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
    final navigationState = Get.find<NavigationState>();

    return Obx(() {
      final currentMode = navigationState.currentMode.value;
      final currentNode = navigationState.currentNode;

      return Scaffold(
        backgroundColor: currentMode == MapViewMode.tactical
            ? VitruvianColors.lighterVellum
            : VitruvianColors.voidBlack,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: VitruvianColors.voidBlack,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        currentMode == MapViewMode.tactical
                            ? 'TACTICAL STREET-TO-STREET VIEW'
                            : 'OVERWORLD PARCHMENT MAP',
                        style: VitruvianTypography.serifTitle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: navigationState.toggleViewMode,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(color: VitruvianColors.sepiaUmber),
                        ),
                        child: Icon(
                          currentMode == MapViewMode.tactical
                              ? Icons.map_outlined
                              : Icons.grid_view_outlined,
                          color: VitruvianColors.agedBone,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: currentMode == MapViewMode.tactical
                    ? _buildTacticalView(context, navigationState, currentNode)
                    : _buildOverworldMap(context, navigationState),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTacticalView(
    BuildContext context,
    NavigationState navigationState,
    NavigationNode currentNode,
  ) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 120,
                  color: VitruvianColors.sepiaUmber.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'CURRENT STREET PRESENCE: ${currentNode.title.toUpperCase()}',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 14,
                    color: VitruvianColors.voidBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
        EtchedContainer(
          margin: const EdgeInsets.all(12),
          backgroundColor: VitruvianColors.voidBlack,
          borderColor: VitruvianColors.sepiaUmber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TERRITORY INTEL',
                  style: VitruvianTypography.serifTitle(
                      fontSize: 15, color: VitruvianColors.sepiaUmber)),
              const SizedBox(height: 4),
              Text(
                currentNode.territoryIntel,
                style: VitruvianTypography.serifBody(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text('STREET-TO-STREET LINKS:',
                  style: VitruvianTypography.monospaceData(fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: currentNode.connectedNodeIds.map((targetId) {
                  final targetNode = navigationState.nodes[targetId]!;
                  return InkWell(
                    onTap: () => navigationState.traverseToNode(targetId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1C18),
                        border: Border.all(color: Colors.cyanAccent),
                      ),
                      child: Text(
                        'TRAVERSE TO: ${targetNode.title}',
                        style: VitruvianTypography.monospaceData(fontSize: 10),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverworldMap(BuildContext context, NavigationState nav) {
    final cities = nav.worldNodes.values.toList();
    final selectedCity = nav.selectedWorldCity;
    final currentCity = nav.currentWorldCity;

    return Stack(
      children: [
        // THE UNIFIED TRANSFORMATION WRAPPER
        InteractiveViewer(
          minScale: 0.35,
          maxScale: 3.5,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(400),
          child: SizedBox(
            width: 2000,
            height: 1125,
            child: Stack(
              children: [
                // LAYER 1: THE BACKGROUND ART
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/world_map.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                // LAYER 2: THE TRAVEL PATHS (CustomPaint)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WorldRoutePainter(cities, currentCity, selectedCity),
                  ),
                ),

                // LAYER 3: THE CITY HITBOX BUTTONS
                ...cities.map((city) {
                  final isSelected = selectedCity.id == city.id;
                  final isCurrent = currentCity.id == city.id;
                  final canTravel = currentCity.connectedCityIds.contains(city.id);

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
                              color: isCurrent
                                  ? const Color(0xFFC89B5D)
                                  : canTravel
                                      ? const Color(0xFF1E3A3A)
                                      : const Color(0xFF151310),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
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
                              city.type == WorldCityType.capital
                                  ? Icons.castle
                                  : city.type == WorldCityType.port
                                      ? Icons.anchor
                                      : Icons.shield,
                              size: isSelected ? 28 : 22,
                              color: isCurrent
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

        // BOTTOM FLOATING INTEL LEDGER
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
                    Row(
                      children: [
                        Icon(
                          selectedCity.type == WorldCityType.capital ? Icons.castle : Icons.anchor,
                          color: const Color(0xFFC89B5D),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedCity.name.toUpperCase(),
                          style: VitruvianTypography.serifTitle(
                            fontSize: 16,
                            color: const Color(0xFFE0C8B0),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2218),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${selectedCity.continent.toUpperCase()} | ${selectedCity.type.name.toUpperCase()}',
                        style: VitruvianTypography.monospaceData(
                          fontSize: 10,
                          color: const Color(0xFFC89B5D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  selectedCity.lore,
                  style: VitruvianTypography.serifBody(
                    fontSize: 13,
                    color: VitruvianColors.agedBone,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentCity.connectedCityIds.contains(selectedCity.id)
                              ? const Color(0xFF3A2C20)
                              : const Color(0xFF1E1C18),
                          foregroundColor: currentCity.connectedCityIds.contains(selectedCity.id)
                              ? Colors.cyanAccent
                              : Colors.white38,
                          side: BorderSide(
                            color: currentCity.connectedCityIds.contains(selectedCity.id)
                                ? Colors.cyanAccent
                                : Colors.transparent,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.flight_takeoff, size: 18),
                        label: Text(
                          currentCity.id == selectedCity.id
                              ? 'CURRENT PRESENCE'
                              : currentCity.connectedCityIds.contains(selectedCity.id)
                                  ? 'TRAVERSE ALONG ROUTE'
                                  : 'ROUTE UNAVAILABLE DIRECTLY',
                          style: VitruvianTypography.monospaceData(fontSize: 11),
                        ),
                        onPressed: currentCity.connectedCityIds.contains(selectedCity.id)
                            ? () {
                                nav.travelToSelectedCity();
                                Get.snackbar('Overworld', 'Traversed to ${selectedCity.name}',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: const Color(0xFF201B15),
                                    colorText: Colors.cyanAccent);
                              }
                            : null,
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
