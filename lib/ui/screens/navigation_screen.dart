import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/navigation_state.dart';
import '../widgets/etched_container.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavigationState>();

    return Obx(() {
      final currentMode = nav.currentMode.value;

      return Scaffold(
        backgroundColor: VitruvianColors.voidBlack,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TOP HEADER BAR WITH BREADCRUMBS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF151310),
                  border: Border(bottom: BorderSide(color: Color(0xFF3A2C20))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            currentMode == MapViewMode.overworld
                                ? Icons.public
                                : currentMode == MapViewMode.city
                                    ? Icons.map_outlined
                                    : Icons.location_on,
                            color: const Color(0xFFC89B5D),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentMode == MapViewMode.overworld
                                  ? 'OVERWORLD PARCHMENT MAP'
                                  : currentMode == MapViewMode.city
                                      ? 'CITY STREETS: ${nav.currentCity?.name.toUpperCase() ?? ""}'
                                      : 'DISTRICT: ${nav.currentLocation?.title.toUpperCase() ?? ""}',
                              style: VitruvianTypography.serifTitle(fontSize: 15, color: const Color(0xFFE0C8B0)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (currentMode != MapViewMode.overworld)
                      InkWell(
                        onTap: nav.toggleViewMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2218),
                            border: Border.all(color: const Color(0xFFC89B5D)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_out, color: Colors.amberAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                currentMode == MapViewMode.location ? 'ZOOM TO CITY' : 'ZOOM TO WORLD',
                                style: VitruvianTypography.monospaceData(fontSize: 10, color: Colors.amberAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // VIEW PORT SWITCHER
              Expanded(
                child: currentMode == MapViewMode.overworld
                    ? _buildOverworldMap(context, nav)
                    : currentMode == MapViewMode.city
                        ? _buildCityStreetMap(context, nav)
                        : _buildLocationView(context, nav),
              ),
            ],
          ),
        ),
      );
    });
  }

  // --- TIER 1: OVERWORLD MAP ---
  Widget _buildOverworldMap(BuildContext context, NavigationState nav) {
    final cities = nav.worldNodes.values.toList();
    final selectedCity = nav.selectedWorldCity;
    final currentCity = nav.currentWorldCity;

    return Stack(
      children: [
        AutoCenterViewer(
          target: currentCity.pos,
          child: SizedBox(
            width: 2000,
            height: 1125,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/world_map.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WorldRoutePainter(cities, currentCity, selectedCity),
                  ),
                ),
                ...cities.map((city) {
                  final isSelected = selectedCity.id == city.id;
                  final isCurrent = currentCity.id == city.id;
                  final canTravel = currentCity.connectedCityIds.contains(city.id);
                  final isUnlocked = nav.unlockedCityIds.contains(city.id);

                  return Positioned(
                    left: city.pos.dx - 28,
                    top: city.pos.dy - 28,
                    child: GestureDetector(
                      onTap: () => nav.selectWorldCity(city.id),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 56 : 48,
                            height: isSelected ? 56 : 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !isUnlocked
                                  ? const Color(0xFF1F1A15)
                                  : isCurrent
                                      ? const Color(0xFFC89B5D)
                                      : canTravel
                                          ? const Color(0xFF1E3A3A)
                                          : const Color(0xFF151310),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : !isUnlocked
                                        ? Colors.redAccent.withValues(alpha: 0.5)
                                        : isCurrent
                                            ? Colors.white70
                                            : canTravel
                                                ? Colors.cyanAccent
                                                : const Color(0xFF5A4A3A),
                                width: isSelected ? 3.0 : 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? Colors.amberAccent.withValues(alpha: 0.6)
                                      : Colors.black87,
                                  blurRadius: isSelected ? 12 : 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              !isUnlocked
                                  ? Icons.lock
                                  : city.type == WorldCityType.capital
                                      ? Icons.castle
                                      : city.type == WorldCityType.port
                                          ? Icons.anchor
                                          : Icons.shield,
                              size: isSelected ? 28 : 22,
                              color: !isUnlocked
                                  ? Colors.redAccent
                                  : isCurrent
                                      ? const Color(0xFF151310)
                                      : canTravel
                                          ? Colors.cyanAccent
                                          : const Color(0xFFC89B5D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151310).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF3A2C20)),
                            ),
                            child: Text(
                              city.name,
                              style: VitruvianTypography.monospaceData(
                                fontSize: 10,
                                color: isSelected ? Colors.amberAccent : VitruvianColors.agedBone,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // OVERWORLD BOTTOM LEDGER
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: EtchedContainer(
            backgroundColor: const Color(0xFF151310).withValues(alpha: 0.95),
            borderColor: const Color(0xFFC89B5D),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            selectedCity.type == WorldCityType.capital ? Icons.castle : Icons.anchor,
                            color: const Color(0xFFC89B5D),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCity.name.toUpperCase(),
                              style: VitruvianTypography.serifTitle(fontSize: 16, color: const Color(0xFFE0C8B0)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2218),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${selectedCity.continent.toUpperCase()} | ${selectedCity.type.name.toUpperCase()}',
                        style: VitruvianTypography.monospaceData(fontSize: 10, color: const Color(0xFFC89B5D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  selectedCity.lore,
                  style: VitruvianTypography.serifBody(fontSize: 13, color: VitruvianColors.agedBone),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentCity.id == selectedCity.id
                              ? const Color(0xFF3E2B15)
                              : currentCity.connectedCityIds.contains(selectedCity.id)
                                  ? const Color(0xFF1E3A3A)
                                  : const Color(0xFF1E1C18),
                          foregroundColor: currentCity.id == selectedCity.id
                              ? Colors.amberAccent
                              : currentCity.connectedCityIds.contains(selectedCity.id)
                                  ? Colors.cyanAccent
                                  : Colors.white38,
                          side: BorderSide(
                            color: currentCity.id == selectedCity.id
                                ? Colors.amberAccent
                                : currentCity.connectedCityIds.contains(selectedCity.id)
                                    ? Colors.cyanAccent
                                    : Colors.transparent,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(
                          currentCity.id == selectedCity.id ? Icons.location_city : Icons.flight_takeoff,
                          size: 18,
                        ),
                        label: Text(
                          currentCity.id == selectedCity.id
                              ? 'ENTER CITY STREETS'
                              : currentCity.connectedCityIds.contains(selectedCity.id)
                                  ? 'TRAVERSE ALONG ROUTE'
                                  : 'ROUTE UNAVAILABLE DIRECTLY',
                          style: VitruvianTypography.monospaceData(fontSize: 12),
                        ),
                        onPressed: () {
                          if (currentCity.id == selectedCity.id) {
                            nav.enterCity(selectedCity.id);
                          } else if (currentCity.connectedCityIds.contains(selectedCity.id)) {
                            nav.travelToSelectedCity();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- TIER 2: CITY STREET MAP ---
  Widget _buildCityStreetMap(BuildContext context, NavigationState nav) {
    final city = nav.currentCity;
    if (city == null) return const Center(child: Text("No City Data Loaded"));

    final cityNodes = nav.nodes.values.where((n) => n.cityId == city.id).toList();

    return Stack(
      children: [
        AutoCenterViewer(
          target: nav.currentNode.mapPos,
          child: SizedBox(
            width: 2000,
            height: 1125,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    city.streetMapImage,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CityRoutePainter(cityNodes, nav.unlockedLocationIds),
                  ),
                ),
                ...cityNodes.map((node) {
                  final isUnlocked = nav.unlockedLocationIds.contains(node.id);

                  return Positioned(
                    left: node.mapPos.dx - 40,
                    top: node.mapPos.dy - 35,
                    child: GestureDetector(
                      onTap: () => nav.moveToLocation(node.id),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isUnlocked ? const Color(0xFF1E3A3A) : const Color(0xFF1F1A15),
                              border: Border.all(
                                color: isUnlocked ? Colors.cyanAccent : Colors.redAccent.withValues(alpha: 0.5),
                                width: isUnlocked ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isUnlocked ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.black87,
                                  blurRadius: isUnlocked ? 10 : 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isUnlocked ? Icons.location_on : Icons.lock,
                              size: 26,
                              color: isUnlocked ? Colors.cyanAccent : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151310).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isUnlocked ? const Color(0xFFC89B5D) : const Color(0xFF3A2C20)),
                            ),
                            child: Text(
                              node.title,
                              style: VitruvianTypography.monospaceData(
                                fontSize: 11,
                                color: isUnlocked ? Colors.amberAccent : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // CITY FLOATING HEADER
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: EtchedContainer(
            backgroundColor: const Color(0xFF151310).withValues(alpha: 0.9),
            borderColor: const Color(0xFFC89B5D),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'SELECT AN UNLOCKED DISTRICT TO ENTER',
                    style: VitruvianTypography.monospaceData(fontSize: 12, color: const Color(0xFFE0C8B0)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2218),
                    foregroundColor: Colors.amberAccent,
                    side: const BorderSide(color: Color(0xFFC89B5D)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.public, size: 16),
                  label: Text('OVERWORLD', style: VitruvianTypography.monospaceData(fontSize: 11)),
                  onPressed: nav.exitToOverworld,
                ),
              ],
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
            color: Colors.black.withValues(alpha: 0.5),
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
                  Colors.black.withValues(alpha: 0.4),
                  const Color(0xFF151310),
                ],
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
                              style: VitruvianTypography.serifTitle(fontSize: 22, color: const Color(0xFFE0C8B0)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A3A),
                              border: Border.all(color: Colors.cyanAccent),
                            ),
                            child: Text(
                              'ACTIVE DISTRICT',
                              style: VitruvianTypography.monospaceData(fontSize: 10, color: Colors.cyanAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.volume_up, size: 16, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              node.ambientAudio,
                              style: VitruvianTypography.serifBody(
                                fontSize: 14,
                                color: Colors.amberAccent.withValues(alpha: 0.9),
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
                      return EtchedContainer(
                        backgroundColor: const Color(0xFF1E1C18),
                        borderColor: const Color(0xFF5A4A3A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, color: Color(0xFFC89B5D), size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  npc,
                                  style: VitruvianTypography.serifTitle(fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2218),
                                foregroundColor: Colors.amberAccent,
                                side: const BorderSide(color: Color(0xFFC89B5D)),
                              ),
                              onPressed: () {
                                Get.snackbar('Interaction', 'Speaking with $npc...',
                                    backgroundColor: const Color(0xFF151310), colorText: Colors.amberAccent);
                              },
                              child: Text('INTERACT', style: VitruvianTypography.monospaceData(fontSize: 11)),
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
                    backgroundColor: const Color(0xFF3E1212),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.redAccent),
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

class _WorldRoutePainter extends CustomPainter {
  final List<WorldCityNode> cities;
  final WorldCityNode currentCity;
  final WorldCityNode selectedCity;

  _WorldRoutePainter(this.cities, this.currentCity, this.selectedCity);

  @override
  void paint(Canvas canvas, Size size) {
    final cityMap = {for (var c in cities) c.id: c};
    final paintedPairs = <String>{};

    final inactivePaint = Paint()
      ..color = const Color(0xFF5A4A3A).withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (var city in cities) {
      for (var targetId in city.connectedCityIds) {
        if (!cityMap.containsKey(targetId)) continue;
        final pairKey = city.id.compareTo(targetId) < 0 ? '${city.id}-$targetId' : '$targetId-${city.id}';
        if (paintedPairs.contains(pairKey)) continue;
        paintedPairs.add(pairKey);

        final target = cityMap[targetId]!;
        final isActiveRoute = (city.id == currentCity.id && targetId == selectedCity.id) ||
                              (targetId == currentCity.id && city.id == selectedCity.id);

        _drawDottedLine(canvas, city.pos, target.pos, isActiveRoute ? activePaint : inactivePaint);
      }
    }
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final maxDist = (p2 - p1).distance;
    const dashLen = 8.0;
    const gapLen = 6.0;
    double currentDist = 0.0;
    final unitVector = (p2 - p1) / maxDist;

    while (currentDist < maxDist) {
      final start = p1 + unitVector * currentDist;
      currentDist += dashLen;
      final end = p1 + unitVector * (currentDist > maxDist ? maxDist : currentDist);
      canvas.drawLine(start, end, paint);
      currentDist += gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _WorldRoutePainter oldDelegate) => true;
}

class _CityRoutePainter extends CustomPainter {
  final List<NavigationNode> nodes;
  final Set<String> unlockedIds;

  _CityRoutePainter(this.nodes, this.unlockedIds);

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (var n in nodes) n.id: n};
    final paintedPairs = <String>{};

    final lockedPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final unlockedPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.75)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var node in nodes) {
      for (var targetId in node.connectedNodeIds) {
        if (!nodeMap.containsKey(targetId)) continue;
        final pairKey = node.id.compareTo(targetId) < 0 ? '${node.id}-$targetId' : '$targetId-${node.id}';
        if (paintedPairs.contains(pairKey)) continue;
        paintedPairs.add(pairKey);

        final target = nodeMap[targetId]!;
        final bothUnlocked = unlockedIds.contains(node.id) && unlockedIds.contains(targetId);

        _drawDottedLine(canvas, node.mapPos, target.mapPos, bothUnlocked ? unlockedPaint : lockedPaint);
      }
    }
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final maxDist = (p2 - p1).distance;
    const dashLen = 6.0;
    const gapLen = 5.0;
    double currentDist = 0.0;
    final unitVector = (p2 - p1) / maxDist;

    while (currentDist < maxDist) {
      final start = p1 + unitVector * currentDist;
      currentDist += dashLen;
      final end = p1 + unitVector * (currentDist > maxDist ? maxDist : currentDist);
      canvas.drawLine(start, end, paint);
      currentDist += gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _CityRoutePainter oldDelegate) => true;
}

class AutoCenterViewer extends StatefulWidget {
  final Widget child;
  final Offset target;
  const AutoCenterViewer({super.key, required this.child, required this.target});

  @override
  State<AutoCenterViewer> createState() => _AutoCenterViewerState();
}

class _AutoCenterViewerState extends State<AutoCenterViewer> {
  late final TransformationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerMap());
  }

  @override
  void didUpdateWidget(AutoCenterViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _centerMap();
    }
  }

  void _centerMap() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final x = -(widget.target.dx) + (size.width / 2);
    final y = -(widget.target.dy) + (size.height / 2);
    _controller.value = Matrix4.identity()..translate(x, y);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.35,
      maxScale: 3.5,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(400),
      child: widget.child,
    );
  }
}
