import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../sandbox/sandbox_launcher.dart';
import '../../states/navigation_state.dart';
import '../combat/combat_widgets.dart' show CombatPalette;
import '../town/town_service_sheets.dart';
import '../widgets/etched_container.dart';
import '../widgets/toast.dart';

/// World map → city streets → district, with one header and a back button.
class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  /// Map-space size of every map canvas (markers are placed in these coordinates).
  static const mapSize = Size(2000, 1125);

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavigationState>();

    return Obx(() {
      final mode = nav.currentMode.value;

      return Scaffold(
        backgroundColor: VitruvianColors.voidBlack,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: const BoxDecoration(
                color: CombatPalette.raised,
                border: Border(bottom: BorderSide(color: CombatPalette.hairlineStrong)),
              ),
              child: Row(
                children: [
                  Icon(
                    mode == MapViewMode.overworld
                        ? Icons.public
                        : mode == MapViewMode.city
                            ? Icons.map_outlined
                            : Icons.location_on_outlined,
                    color: CombatPalette.brass,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mode == MapViewMode.overworld
                          ? 'TAP A CITY · DOUBLE-TAP TO TRAVEL'
                          : mode == MapViewMode.city
                              ? 'WORLD › ${(nav.currentCity?.name ?? '').split(' (').first.toUpperCase()}'
                              : '${(nav.currentCity?.name ?? '').split(' (').first.toUpperCase()} › ${(nav.currentLocation?.title ?? '').toUpperCase()}',
                      style: VitruvianTypography.serifTitle(fontSize: 15, color: CombatPalette.parchment),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (mode != MapViewMode.overworld)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: CombatPalette.brass,
                        side: const BorderSide(color: CombatPalette.hairlineStrong),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: mode == MapViewMode.location ? nav.exitToCityStreets : nav.exitToOverworld,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(mode == MapViewMode.location ? 'STREETS' : 'WORLD',
                          style: VitruvianTypography.monospaceData(fontSize: 11, color: CombatPalette.brass)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: mode == MapViewMode.overworld || mode == MapViewMode.tactical
                  ? _buildOverworldMap(context, nav)
                  : mode == MapViewMode.city
                      ? _buildCityStreetMap(context, nav)
                      : _buildLocationView(context, nav),
            ),
          ],
        ),
      );
    });
  }

  // ─── Markers ───

  /// A map pin sized in map units, so it scales with zoom like the map's own ink.
  static Widget _marker({
    required IconData icon,
    required String label,
    required Color ring,
    required Color fill,
    required Color iconColor,
    bool selected = false,
    String? tag,
    double opacity = 1,
  }) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: CombatPalette.brass,
              child: Text(tag, style: VitruvianTypography.monospaceData(fontSize: 16, color: CombatPalette.ground, fontWeight: FontWeight.w700)),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 76 : 64,
            height: selected ? 76 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: selected ? CombatPalette.bone : ring, width: selected ? 5 : 3.5),
              boxShadow: [
                BoxShadow(
                  color: selected ? CombatPalette.brass.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.7),
                  blurRadius: selected ? 18 : 8,
                ),
              ],
            ),
            child: Icon(icon, size: selected ? 38 : 32, color: iconColor),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CombatPalette.raised.withValues(alpha: 0.92),
              border: Border.all(color: selected ? CombatPalette.brass : CombatPalette.hairlineStrong, width: 2),
            ),
            child: Text(label,
                style: VitruvianTypography.monospaceData(fontSize: 18, color: selected ? CombatPalette.brass : CombatPalette.bone)),
          ),
        ],
      ),
    );
  }

  /// Paint order: ordinary cities first, then the selected one, then where you are.
  static int _rank(WorldCityNode c, WorldCityNode current, WorldCityNode selected) =>
      c.id == current.id ? 2 : c.id == selected.id ? 1 : 0;

  static IconData _cityIcon(WorldCityNode city) {
    if (city.id == 'island_of_skulls') return Icons.dangerous_outlined;
    switch (city.type) {
      case WorldCityType.capital:
        return Icons.castle_outlined;
      case WorldCityType.port:
        return Icons.anchor;
      case WorldCityType.fort:
        return Icons.shield_outlined;
      case WorldCityType.tradeCity:
        return Icons.storefront_outlined;
    }
  }

  void _note(String message) {
    showToast('', message, duration: const Duration(seconds: 2));
  }

  // ─── World map ───

  Widget _buildOverworldMap(BuildContext context, NavigationState nav) {
    final cities = nav.worldNodes.values.toList();
    final selected = nav.selectedWorldCity;
    final current = nav.currentWorldCity;
    final route = nav.routeTo(selected.id);

    void travelOrEnter(WorldCityNode city) {
      nav.selectWorldCity(city.id);
      if (city.id == 'island_of_skulls') {
        SandboxLauncher.openSandbox(context);
      } else if (city.id == nav.currentWorldCityId.value) {
        final why = nav.enterCity(city.id);
        if (why != null) _note(why);
      } else if (nav.travelToSelectedCity() == null) {
        _note(nav.unlockedCityIds.contains(city.id) ? 'No open route to ${city.name} yet.' : '${city.name} is locked.');
      }
    }

    return Stack(
      children: [
        MapViewer(
          target: current.pos,
          focusY: 0.36,
          child: SizedBox.fromSize(
            size: mapSize,
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset('assets/images/maps/world_aethelgard.webp', fit: BoxFit.cover)),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WorldRoutePainter(cities, nav.unlockedCityIds.toSet(), [current.id, ...route]),
                  ),
                ),
                ...([...cities]..sort((a, b) => _rank(a, current, selected).compareTo(_rank(b, current, selected)))).map((city) {
                  final unlocked = nav.unlockedCityIds.contains(city.id);
                  final isCurrent = city.id == current.id;
                  final reachable = unlocked && nav.routeTo(city.id).isNotEmpty;
                  return Positioned(
                    left: city.pos.dx - 110,
                    top: city.pos.dy - (isCurrent ? 62 : 38),
                    width: 220,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => nav.selectWorldCity(city.id),
                      onDoubleTap: () => travelOrEnter(city),
                      child: Semantics(
                        button: true,
                        label: '${city.name}${isCurrent ? ', you are here' : unlocked ? '' : ', locked'}',
                        child: _marker(
                          icon: unlocked ? _cityIcon(city) : Icons.lock_outline,
                          label: city.name.replaceAll(' (Sandbox)', ''),
                          selected: city.id == selected.id,
                          tag: isCurrent ? 'YOU ARE HERE' : null,
                          ring: isCurrent
                              ? CombatPalette.brass
                              : reachable
                                  ? CombatPalette.parchment
                                  : unlocked
                                      ? CombatPalette.sepia
                                      : CombatPalette.rust,
                          fill: isCurrent ? CombatPalette.brass : CombatPalette.raised,
                          iconColor: isCurrent
                              ? CombatPalette.ground
                              : unlocked
                                  ? CombatPalette.parchment
                                  : CombatPalette.wound,
                          opacity: unlocked ? 1 : 0.75,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _worldLedger(context, nav, selected, current, route, travelOrEnter),
        ),
      ],
    );
  }

  Widget _worldLedger(BuildContext context, NavigationState nav, WorldCityNode selected, WorldCityNode current,
      List<String> route, void Function(WorldCityNode) act) {
    final unlocked = nav.unlockedCityIds.contains(selected.id);
    final isCurrent = selected.id == current.id;
    final sandbox = selected.id == 'island_of_skulls';

    String label;
    bool enabled = true;
    String? detail;
    if (sandbox) {
      label = 'OPEN THE PROVING GROUNDS';
    } else if (!unlocked) {
      label = 'LOCKED';
      enabled = false;
      detail = 'No route is known. The chronicle may reveal one.';
    } else if (isCurrent) {
      if (nav.isCharted(selected.id)) {
        label = 'ENTER CITY STREETS';
      } else {
        label = 'STREETS NOT YET CHARTED';
        enabled = false;
        detail = 'You are here, but this city has no street map yet.';
      }
    } else if (route.isEmpty) {
      label = 'NO OPEN ROUTE';
      enabled = false;
      detail = 'Every road there runs through a locked region.';
    } else {
      label = route.length == 1 ? 'TRAVEL' : 'TRAVEL · ${route.length} STOPS';
      if (route.length > 1) {
        detail = 'Via ${route.sublist(0, route.length - 1).map((id) => nav.worldNodes[id]!.name.split(' (').first).join(' → ')}';
      }
    }

    return EtchedContainer(
      backgroundColor: CombatPalette.raised.withValues(alpha: 0.96),
      borderColor: CombatPalette.hairlineStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(selected.name.toUpperCase(),
                    style: VitruvianTypography.serifTitle(fontSize: 16, color: CombatPalette.parchment),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${selected.continent.toUpperCase()} · ${selected.type.name.toUpperCase()}',
                  style: VitruvianTypography.monospaceData(fontSize: 10, color: CombatPalette.brass)),
            ],
          ),
          const SizedBox(height: 6),
          Text(selected.lore,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: VitruvianTypography.serifBody(fontSize: 13, color: CombatPalette.bone)),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(detail, style: VitruvianTypography.serifBody(fontSize: 12, color: CombatPalette.ash).copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: enabled ? CombatPalette.brass : Colors.transparent,
              foregroundColor: enabled ? CombatPalette.ground : CombatPalette.ash,
              disabledForegroundColor: CombatPalette.ash,
              side: BorderSide(color: enabled ? CombatPalette.brass : CombatPalette.hairlineStrong),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: enabled ? () => act(selected) : null,
            child: Text(label, style: VitruvianTypography.monospaceData(fontSize: 12, color: enabled ? CombatPalette.ground : CombatPalette.ash)),
          ),
        ],
      ),
    );
  }

  // ─── City streets ───

  Widget _buildCityStreetMap(BuildContext context, NavigationState nav) {
    final city = nav.currentCity;
    if (city == null) return const Center(child: Text('No city data loaded'));

    final cityNodes = nav.nodes.values.where((n) => n.cityId == city.id).toList();
    final presentId = nav.presentLocationId.value;
    final present = presentId != null ? nav.nodes[presentId] : null;
    final unlocked = nav.unlockedLocationIds.toSet();
    final focus = (present != null && present.cityId == city.id) ? present.mapPos : cityNodes.first.mapPos;

    return Stack(
      children: [
        MapViewer(
          target: focus,
          focusY: 0.45,
          child: SizedBox.fromSize(
            size: mapSize,
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset(city.streetMapImage, fit: BoxFit.cover)),
                Positioned.fill(child: CustomPaint(painter: _CityRoutePainter(cityNodes, unlocked))),
                ...cityNodes.map((node) {
                  final isUnlocked = unlocked.contains(node.id);
                  final isHere = node.id == presentId;
                  return Positioned(
                    left: node.mapPos.dx - 150,
                    top: node.mapPos.dy - (isHere ? 62 : 38),
                    width: 300,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final why = nav.moveToLocation(node.id);
                        if (why != null) _note(why);
                      },
                      child: Semantics(
                        button: true,
                        label: '${node.title}${isHere ? ', you are here' : isUnlocked ? '' : ', locked'}',
                        child: _marker(
                          icon: isUnlocked ? Icons.location_on_outlined : Icons.lock_outline,
                          label: node.title,
                          tag: isHere ? 'YOU ARE HERE' : null,
                          ring: isHere ? CombatPalette.brass : isUnlocked ? CombatPalette.parchment : CombatPalette.rust,
                          fill: isHere ? CombatPalette.brass : CombatPalette.raised,
                          iconColor: isHere ? CombatPalette.ground : isUnlocked ? CombatPalette.parchment : CombatPalette.wound,
                          opacity: isUnlocked ? 1 : 0.75,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: EtchedContainer(
            backgroundColor: CombatPalette.raised.withValues(alpha: 0.94),
            borderColor: CombatPalette.hairlineStrong,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              '${unlocked.where((id) => nav.nodes[id]?.cityId == city.id).length} of ${cityNodes.length} districts open · '
              'tap one to go there${present != null ? ' · you are at ${present.title}' : ''}',
              style: VitruvianTypography.serifBody(fontSize: 13, color: CombatPalette.bone),
            ),
          ),
        ),
      ],
    );
  }

  // --- TIER 3: LOCATION NODE DISTRICT VIEW ---
  Widget _buildLocationView(BuildContext context, NavigationState nav) {
    final node = nav.currentLocation;
    if (node == null) return const Center(child: Text("No District Loaded"));

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            node.backgroundImage,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.1),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xEE151310),
                ],
                stops: const [0.0, 0.62],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EtchedContainer(
                  backgroundColor: const Color(0xFF151310).withValues(alpha: 0.85),
                  borderColor: const Color(0xFFC89B5D),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              node.title.toUpperCase(),
                              style: VitruvianTypography.serifTitle(fontSize: 18, color: const Color(0xFFE0C8B0)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: CombatPalette.brass,
                            child: Text(
                              'YOU ARE HERE',
                              style: VitruvianTypography.monospaceData(fontSize: 10, color: CombatPalette.ground),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.volume_up, size: 16, color: CombatPalette.brass),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              node.ambientAudio,
                              style: VitruvianTypography.serifBody(
                                fontSize: 14,
                                color: CombatPalette.brass,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF3A2C20), height: 24),
                      Text(
                        node.description,
                        style: VitruvianTypography.serifBody(fontSize: 15, color: VitruvianColors.agedBone),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A15),
                          border: Border.all(color: const Color(0xFF5A4A3A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TERRITORY INTEL:',
                              style: VitruvianTypography.monospaceData(fontSize: 11, color: const Color(0xFFC89B5D)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              node.territoryIntel,
                              style: VitruvianTypography.serifBody(fontSize: 13, color: const Color(0xFFE0C8B0)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'LOCAL INTERACTIONS & NPCS:',
                  style: VitruvianTypography.monospaceData(fontSize: 13, color: const Color(0xFFC89B5D)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: node.npcs.length,
                    separatorBuilder: (context, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final npc = node.npcs[index];
                      final service = node.npcServices[npc];
                      return EtchedContainer(
                        backgroundColor: const Color(0xFF1E1C18),
                        borderColor: const Color(0xFF5A4A3A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFFC89B5D), size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      npc,
                                      style: VitruvianTypography.serifTitle(fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2218),
                                foregroundColor: CombatPalette.brass,
                                side: const BorderSide(color: Color(0xFFC89B5D)),
                              ),
                              onPressed: () {
                                if (service != null) {
                                  showTownService(context, service, npc);
                                } else {
                                  _note('$npc has nothing to say yet.');
                                }
                              },
                              child: Text(service != null ? townServiceLabel(service) : 'INTERACT',
                                  style: VitruvianTypography.monospaceData(fontSize: 11)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CombatPalette.raised,
                    foregroundColor: CombatPalette.brass,
                    side: const BorderSide(color: CombatPalette.hairlineStrong),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.exit_to_app),
                  label: Text('RETURN TO CITY STREETS', style: VitruvianTypography.monospaceData(fontSize: 13)),
                  onPressed: nav.exitToCityStreets,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Route painters ──────────────────────────────────────────────────────────

void _dashed(Canvas canvas, Offset p1, Offset p2, Paint paint, {double dash = 10, double gap = 8}) {
  final dist = (p2 - p1).distance;
  if (dist == 0) return;
  final unit = (p2 - p1) / dist;
  double at = 0;
  while (at < dist) {
    canvas.drawLine(p1 + unit * at, p1 + unit * math.min(at + dash, dist), paint);
    at += dash + gap;
  }
}

/// World routes: the planned route (current → selected) in brass, open roads in
/// sepia, roads touching a locked region faint.
class _WorldRoutePainter extends CustomPainter {
  final List<WorldCityNode> cities;
  final Set<String> unlocked;
  final List<String> path;

  _WorldRoutePainter(this.cities, this.unlocked, this.path);

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final c in cities) c.id: c};
    final onPath = <String>{};
    for (var i = 0; i + 1 < path.length; i++) {
      final a = path[i], b = path[i + 1];
      onPath.add(a.compareTo(b) < 0 ? '$a-$b' : '$b-$a');
    }
    final done = <String>{};
    final open = Paint()
      ..color = CombatPalette.sepia.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final shut = Paint()
      ..color = CombatPalette.rust.withValues(alpha: 0.45)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final planned = Paint()
      ..color = CombatPalette.brass
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    for (final c in cities) {
      for (final t in c.connectedCityIds) {
        final other = byId[t];
        if (other == null) continue;
        final key = c.id.compareTo(t) < 0 ? '${c.id}-$t' : '$t-${c.id}';
        if (!done.add(key)) continue;
        final paint = onPath.contains(key)
            ? planned
            : unlocked.contains(c.id) && unlocked.contains(t)
                ? open
                : shut;
        _dashed(canvas, c.pos, other.pos, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorldRoutePainter old) =>
      old.path.join() != path.join() || old.unlocked.length != unlocked.length;
}

class _CityRoutePainter extends CustomPainter {
  final List<NavigationNode> nodes;
  final Set<String> unlocked;

  _CityRoutePainter(this.nodes, this.unlocked);

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final n in nodes) n.id: n};
    final done = <String>{};
    final open = Paint()
      ..color = CombatPalette.brass.withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final shut = Paint()
      ..color = CombatPalette.rust.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final n in nodes) {
      for (final t in n.connectedNodeIds) {
        final other = byId[t];
        if (other == null) continue;
        final key = n.id.compareTo(t) < 0 ? '${n.id}-$t' : '$t-${n.id}';
        if (!done.add(key)) continue;
        _dashed(canvas, n.mapPos, other.mapPos,
            unlocked.contains(n.id) && unlocked.contains(t) ? open : shut, dash: 9, gap: 7);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CityRoutePainter old) =>
      old.unlocked.length != unlocked.length || !old.unlocked.containsAll(unlocked);
}

// ─── Map viewer ──────────────────────────────────────────────────────────────

/// Pan/zoom viewer for a fixed-size map canvas. Opens zoomed out (the map always
/// covers the viewport) with [target] centred horizontally and at [focusY] of the
/// visible height, so it sits above any bottom panel. Re-centres when the target moves.
class MapViewer extends StatefulWidget {
  final Widget child;
  final Offset target;
  final double focusY;
  final Size canvas;

  const MapViewer({
    super.key,
    required this.child,
    required this.target,
    this.focusY = 0.5,
    this.canvas = NavigationScreen.mapSize,
  });

  @override
  State<MapViewer> createState() => _MapViewerState();
}

class _MapViewerState extends State<MapViewer> {
  final _controller = TransformationController();
  Size? _viewport;

  double _minScale(Size v) => math.max(v.width / widget.canvas.width, v.height / widget.canvas.height);

  void _center(Size v) {
    final s = math.max(_minScale(v), 0.5);
    final w = widget.canvas.width * s, h = widget.canvas.height * s;
    final tx = (v.width / 2 - widget.target.dx * s).clamp(v.width - w, 0.0);
    final ty = (v.height * widget.focusY - widget.target.dy * s).clamp(v.height - h, 0.0);
    _controller.value = Matrix4.diagonal3Values(s, s, 1)..setTranslationRaw(tx, ty, 0);
  }

  @override
  void didUpdateWidget(covariant MapViewer old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target && _viewport != null) _center(_viewport!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final v = constraints.biggest;
      if (_viewport != v) {
        _viewport = v;
        _center(v);
      }
      return ClipRect(
        child: InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: _minScale(v),
          maxScale: 2.5,
          boundaryMargin: EdgeInsets.zero,
          child: widget.child,
        ),
      );
    });
  }
}
