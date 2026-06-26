import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/navigation_state.dart';
import '../widgets/etched_container.dart';

class NavigationScreen extends StatelessWidget {
  final NavigationState navigationState;

  const NavigationScreen({super.key, required this.navigationState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: navigationState,
      builder: (context, child) {
        final currentMode = navigationState.currentMode;
        final currentNode = navigationState.currentNode;

        return Scaffold(
          backgroundColor: currentMode == MapViewMode.tactical
              ? VitruvianColors.lighterVellum
              : VitruvianColors.voidBlack,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dual-Map Switcher
                Container(
                  padding: const EdgeInsets.all(12),
                  color: VitruvianColors.voidBlack,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentMode == MapViewMode.tactical
                            ? 'TACTICAL TOPOGRAPHICAL VIEW'
                            : 'OVERWORLD PARCHMENT MAP',
                        style: VitruvianTypography.serifTitle(fontSize: 16),
                      ),
                      InkWell(
                        onTap: navigationState.toggleViewMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: VitruvianColors.sepiaUmber),
                          ),
                          child: Text(
                            'SWITCH TO ${currentMode == MapViewMode.tactical ? "OVERWORLD" : "TACTICAL"}',
                            style: VitruvianTypography.monospaceData(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Map Display Area
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currentMode == MapViewMode.tactical ? Icons.map : Icons.public,
                              size: 120,
                              color: currentMode == MapViewMode.tactical
                                  ? VitruvianColors.sepiaUmber.withValues(alpha: 0.3)
                                  : VitruvianColors.agedBone.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'CURRENT PRESENCE: ${currentNode.title.toUpperCase()}',
                              style: VitruvianTypography.monospaceData(
                                fontSize: 14,
                                color: currentMode == MapViewMode.tactical
                                    ? VitruvianColors.voidBlack
                                    : VitruvianColors.agedBone,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Territory Intel Panel
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
                      Text('TRAVERSAL LINK-LINES:',
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
            ),
          ),
        );
      },
    );
  }
}
