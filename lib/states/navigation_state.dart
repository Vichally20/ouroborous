import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum MapViewMode { tactical, overworld }

enum WorldCityType { capital, port, fort, tradeCity }

class NavigationNode {
  final String id;
  final String title;
  final String description;
  final List<String> connectedNodeIds;
  final String territoryIntel;

  const NavigationNode({
    required this.id,
    required this.title,
    required this.description,
    required this.connectedNodeIds,
    required this.territoryIntel,
  });
}

class WorldCityNode {
  final String id;
  final String name;
  final String continent;
  final WorldCityType type;
  final Offset pos;
  final List<String> connectedCityIds;
  final String lore;

  const WorldCityNode({
    required this.id,
    required this.name,
    required this.continent,
    required this.type,
    required this.pos,
    required this.connectedCityIds,
    required this.lore,
  });
}

class NavigationState extends GetxController {
  final currentMode = MapViewMode.tactical.obs;
  final currentNodeId = 'undercroft'.obs;
  final isShowingMap = false.obs;

  // Overworld reactive state
  final currentWorldCityId = 'aethel_cap'.obs;
  final selectedWorldCityId = 'aethel_cap'.obs;

  final Map<String, NavigationNode> nodes = const {
    'undercroft': NavigationNode(
      id: 'undercroft',
      title: 'The Undercroft',
      description: 'A damp subterranean chamber smelling of old earth and sacrificial blood.',
      connectedNodeIds: ['n1'],
      territoryIntel: 'Monolithic black stone altar. Rhythmic clicking echoing from the shadows.',
    ),
    'n1': NavigationNode(
      id: 'n1',
      title: 'Vichally Amphitheater Scriptorium',
      description: 'A vaulted anatomical theater smelling of dried blood and old vellum.',
      connectedNodeIds: ['n2', 'n3'],
      territoryIntel: 'High concentrations of hermetic scholars and clinical scribes.',
    ),
    'n2': NavigationNode(
      id: 'n2',
      title: 'The Scribe Cobblestones',
      description: 'Rain-slicked historical alleyways winding past ancient apothecaries.',
      connectedNodeIds: ['n1'],
      territoryIntel: 'Low patrol presence. High risk of sanity depletion after dusk.',
    ),
    'n3': NavigationNode(
      id: 'n3',
      title: 'Da Vinci Cartography Vault',
      description: 'Subterranean archive storing historical parchment maps of the Known World.',
      connectedNodeIds: ['n1'],
      territoryIntel: 'Secure repository. Vital for unlocking Overworld cartographic markers.',
    ),
  };

  final Map<String, WorldCityNode> worldNodes = const {
    'aethel_cap': WorldCityNode(
      id: 'aethel_cap',
      name: 'Aethel Capital',
      continent: 'Aethel',
      type: WorldCityType.capital,
      pos: Offset(680, 520),
      connectedCityIds: ['riverend_port', 'frost_keep'],
      lore: 'Seat of the High King. Spire-topped marble citadel guarded by hermetic knights.',
    ),
    'riverend_port': WorldCityNode(
      id: 'riverend_port',
      name: 'City-State of Riverend',
      continent: 'Aethel',
      type: WorldCityType.port,
      pos: Offset(740, 720),
      connectedCityIds: ['aethel_cap', 'coral_harbor', 'gilded_shore'],
      lore: 'Busy southern trade port where the Skyhold river meets the Whispering Sea.',
    ),
    'frost_keep': WorldCityNode(
      id: 'frost_keep',
      name: 'Frost Keep',
      continent: 'Tharun',
      type: WorldCityType.capital,
      pos: Offset(560, 240),
      connectedCityIds: ['aethel_cap', 'skaldic_holds'],
      lore: 'Immovable northern fortress carved from glacial ice and ancient wyvern bone.',
    ),
    'skaldic_holds': WorldCityNode(
      id: 'skaldic_holds',
      name: 'Skaldic Holds',
      continent: 'Tharun',
      type: WorldCityType.fort,
      pos: Offset(280, 260),
      connectedCityIds: ['frost_keep'],
      lore: 'Rugged barbarian longhouses nestled beneath the howling Wyvernspire Peaks.',
    ),
    'sylvanis': WorldCityNode(
      id: 'sylvanis',
      name: 'Sylvanis',
      continent: 'Veridia',
      type: WorldCityType.capital,
      pos: Offset(1200, 270),
      connectedCityIds: ['gilded_shore', 'feridian'],
      lore: 'Lush sylvan capital built seamlessly around colossal World-Tree roots.',
    ),
    'gilded_shore': WorldCityNode(
      id: 'gilded_shore',
      name: 'Gilded Shore',
      continent: 'Veridia',
      type: WorldCityType.tradeCity,
      pos: Offset(1250, 410),
      connectedCityIds: ['sylvanis', 'riverend_port', 'suns_reach'],
      lore: 'Wealthy merchant city-state dominating the Whispering Sea spice routes.',
    ),
    'feridian': WorldCityNode(
      id: 'feridian',
      name: 'Feridian Frosthold',
      continent: 'Veridia',
      type: WorldCityType.fort,
      pos: Offset(1550, 180),
      connectedCityIds: ['sylvanis'],
      lore: 'Isolated northern garrison watching the Northern Abyss for serpentine Leviathans.',
    ),
    'sandspire': WorldCityNode(
      id: 'sandspire',
      name: 'Sandspire',
      continent: 'Zandoria',
      type: WorldCityType.capital,
      pos: Offset(1100, 750),
      connectedCityIds: ['coral_harbor'],
      lore: 'Golden palace kingdom rising above dense tropical canopy and ancient ruins.',
    ),
    'coral_harbor': WorldCityNode(
      id: 'coral_harbor',
      name: 'Coral Harbor',
      continent: 'Zandoria',
      type: WorldCityType.port,
      pos: Offset(980, 780),
      connectedCityIds: ['sandspire', 'riverend_port'],
      lore: 'Sheltered nautical haven built upon glowing pink coral reef foundations.',
    ),
    'al_khazad': WorldCityNode(
      id: 'al_khazad',
      name: 'Al-Khazad',
      continent: 'Oronth',
      type: WorldCityType.capital,
      pos: Offset(1680, 560),
      connectedCityIds: ['suns_reach'],
      lore: 'Magnificent crimson sandstone domes shimmering amid the Eldertooth dunes.',
    ),
    'suns_reach': WorldCityNode(
      id: 'suns_reach',
      name: 'Sun\'s Reach Port',
      continent: 'Oronth',
      type: WorldCityType.port,
      pos: Offset(1450, 550),
      connectedCityIds: ['al_khazad', 'gilded_shore'],
      lore: 'Scorched harbor receiving exotic silk from the Great Eastern Ocean.',
    ),
  };

  NavigationNode get currentNode => nodes[currentNodeId.value]!;
  WorldCityNode get currentWorldCity => worldNodes[currentWorldCityId.value]!;
  WorldCityNode get selectedWorldCity => worldNodes[selectedWorldCityId.value]!;

  void toggleViewMode() {
    currentMode.value = currentMode.value == MapViewMode.tactical
        ? MapViewMode.overworld
        : MapViewMode.tactical;
  }

  void traverseToNode(String nodeId) {
    if (nodes.containsKey(nodeId)) {
      currentNodeId.value = nodeId;
    }
  }

  void selectWorldCity(String cityId) {
    if (worldNodes.containsKey(cityId)) {
      selectedWorldCityId.value = cityId;
    }
  }

  void travelToSelectedCity() {
    final targetId = selectedWorldCityId.value;
    final current = currentWorldCity;
    if (current.connectedCityIds.contains(targetId)) {
      currentWorldCityId.value = targetId;
    }
  }

  void toggleChronicleMap() {
    isShowingMap.value = !isShowingMap.value;
  }
}
