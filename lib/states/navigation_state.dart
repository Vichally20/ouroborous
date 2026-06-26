import 'package:flutter/foundation.dart';

enum MapViewMode { overworld, tactical }

class MapNode {
  final String id;
  final String title;
  final String territoryIntel;
  final List<String> connectedNodeIds;
  final bool isUnlocked;

  const MapNode({
    required this.id,
    required this.title,
    required this.territoryIntel,
    required this.connectedNodeIds,
    this.isUnlocked = true,
  });
}

class NavigationState extends ChangeNotifier {
  MapViewMode currentMode = MapViewMode.tactical;
  String currentPresenceNodeId = 'n1';

  final Map<String, MapNode> nodes = {
    'n1': const MapNode(
      id: 'n1',
      title: 'Anatomical Theater District',
      territoryIntel: 'Clinical amphitheater abandoned during the Great Plague outbreak.',
      connectedNodeIds: ['n2', 'n3'],
    ),
    'n2': const MapNode(
      id: 'n2',
      title: 'Scribe Archives',
      territoryIntel: 'Vaulted library smelling of decaying vellum and ozone.',
      connectedNodeIds: ['n1'],
    ),
    'n3': const MapNode(
      id: 'n3',
      title: 'Hermetic Catacombs',
      territoryIntel: 'Subterranean ossuary lined with femur arches.',
      connectedNodeIds: ['n1'],
    ),
  };

  MapNode get currentNode => nodes[currentPresenceNodeId]!;

  void toggleViewMode() {
    currentMode = currentMode == MapViewMode.tactical
        ? MapViewMode.overworld
        : MapViewMode.tactical;
    notifyListeners();
  }

  void traverseToNode(String targetId) {
    if (currentNode.connectedNodeIds.contains(targetId)) {
      currentPresenceNodeId = targetId;
      notifyListeners();
    }
  }
}
