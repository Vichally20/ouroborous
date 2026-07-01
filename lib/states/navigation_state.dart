import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum MapViewMode { overworld, city, location, tactical }

enum WorldCityType { capital, port, fort, tradeCity }

class CityData {
  final String id;
  final String name;
  final String iconImage;
  final String streetMapImage;
  final bool defaultLocked;
  final List<String> locationNodes;

  const CityData({
    required this.id,
    required this.name,
    required this.iconImage,
    required this.streetMapImage,
    required this.defaultLocked,
    required this.locationNodes,
  });
}

class NavigationNode {
  final String id;
  final String cityId;
  final String title;
  final String description;
  final String territoryIntel;
  final String backgroundImage;
  final String ambientAudio;
  final List<String> connectedNodeIds;
  final List<String> npcs;
  final bool defaultLocked;
  final Offset mapPos; // Coordinates on the 2000x1125 city map canvas

  const NavigationNode({
    required this.id,
    required this.cityId,
    required this.title,
    required this.description,
    required this.territoryIntel,
    required this.backgroundImage,
    required this.ambientAudio,
    required this.connectedNodeIds,
    this.npcs = const [],
    this.defaultLocked = false,
    required this.mapPos,
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
  final currentMode = MapViewMode.overworld.obs;
  final isShowingMap = false.obs;

  // Overworld reactive state
  final currentWorldCityId = 'aethel_cap'.obs;
  final selectedWorldCityId = 'aethel_cap'.obs;

  // City & Location reactive state
  final currentCityId = RxnString('aethel_cap');
  final currentLocationId = RxnString();

  final unlockedCityIds = <String>{'aethel_cap', 'riverend_port', 'frost_keep', 'island_of_skulls'}.obs;
  final unlockedLocationIds = <String>{'undercroft', 'n1', 'slums'}.obs;

  final Map<String, CityData> cities = const {
    'aethel_cap': CityData(
      id: 'aethel_cap',
      name: 'Bowerstone (Aethel Capital)',
      iconImage: 'assets/images/world_map.jpg',
      streetMapImage: 'assets/images/bowerstone_map.jpg', // Grand Map of Bowerstone
      defaultLocked: false,
      locationNodes: ['undercroft', 'n1', 'n2', 'n3', 'slums', 'market', 'docks', 'keep'],
    ),
  };

  final Map<String, NavigationNode> nodes = const {
    'undercroft': NavigationNode(
      id: 'undercroft',
      cityId: 'aethel_cap',
      title: 'The Undercroft Entrance',
      description: 'A damp subterranean chamber smelling of old earth and sacrificial blood beneath East Gate.',
      territoryIntel: 'Monolithic black stone altar. Rhythmic clicking echoing from the shadows.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Rhythmic clicking echoing from deep shadows...',
      connectedNodeIds: ['n1', 'slums'],
      npcs: ['Crypt Guard'],
      defaultLocked: false,
      mapPos: Offset(1650, 680),
    ),
    'n1': NavigationNode(
      id: 'n1',
      cityId: 'aethel_cap',
      title: 'Vichally Amphitheater Scriptorium',
      description: 'A vaulted anatomical theater smelling of dried blood and old vellum near the Temple of the Moon.',
      territoryIntel: 'High concentrations of hermetic scholars and clinical scribes.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Low murmur of scholars scribbling on parchment...',
      connectedNodeIds: ['undercroft', 'n2', 'n3'],
      npcs: ['Anatomist-General', 'Third Chair Scribe'],
      defaultLocked: false,
      mapPos: Offset(1600, 480),
    ),
    'n2': NavigationNode(
      id: 'n2',
      cityId: 'aethel_cap',
      title: 'The Scribe Cobblestones',
      description: 'Rain-slicked historical alleyways winding past ancient apothecaries and tavern courtyards.',
      territoryIntel: 'Low patrol presence. High risk of sanity depletion after dusk.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Distant clinking of glasses and rain dripping on stone...',
      connectedNodeIds: ['n1', 'market'],
      npcs: ['Shady Apothecary'],
      defaultLocked: false,
      mapPos: Offset(680, 520),
    ),
    'n3': NavigationNode(
      id: 'n3',
      cityId: 'aethel_cap',
      title: 'Da Vinci Cartography Vault',
      description: 'Subterranean archive beneath the Adventurers Guild storing historical parchment maps.',
      territoryIntel: 'Secure repository. Vital for unlocking Overworld cartographic markers.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Rustling maps and ticking brass astrolabes...',
      connectedNodeIds: ['n1', 'keep'],
      npcs: ['Master Cartographer'],
      defaultLocked: false,
      mapPos: Offset(1450, 320),
    ),
    'slums': NavigationNode(
      id: 'slums',
      cityId: 'aethel_cap',
      title: 'Toe Shambles & Scavenger Run',
      description: 'Crowded wooden hovels and muddy pathways bordering the southern wall.',
      territoryIntel: 'Heavy beggar activity. High probability of acquiring black market contraband.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Crowd chatter, coughing, and creaking timber...',
      connectedNodeIds: ['undercroft', 'market', 'docks'],
      npcs: ['Beggar Informant', 'Scavenger Merchant'],
      defaultLocked: false,
      mapPos: Offset(1300, 780),
    ),
    'market': NavigationNode(
      id: 'market',
      cityId: 'aethel_cap',
      title: 'The Grand Bazaar (High Street)',
      description: 'The bustling commercial heart of Bowerstone filled with exotic goods and armorers.',
      territoryIntel: 'Heavily guarded trade hub. Prime location for weapon upgrades and rare potions.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Vendors shouting prices and coins clinking...',
      connectedNodeIds: ['slums', 'n2', 'docks'],
      npcs: ['Master Blacksmith', 'Potion Seller'],
      defaultLocked: true, // Locked initially!
      mapPos: Offset(1000, 680),
    ),
    'docks': NavigationNode(
      id: 'docks',
      cityId: 'aethel_cap',
      title: 'Silverflow Docks & Rusty Anchor',
      description: 'Misty riverfront piers where smuggler vessels dock beside waterfront taverns.',
      territoryIntel: 'Smuggler territory. Naval patrol shifts change every three hours.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Seagulls cawing, creaking ship hulls, and water lapping against wood...',
      connectedNodeIds: ['slums', 'market'],
      npcs: ['Tavern Barkeep', 'Smuggler Captain'],
      defaultLocked: true, // Locked initially!
      mapPos: Offset(500, 780),
    ),
    'keep': NavigationNode(
      id: 'keep',
      cityId: 'aethel_cap',
      title: 'The Ducal Keep',
      description: 'Heavily fortified stone citadel overlooking Bowerstone, surrounded by royal guards.',
      territoryIntel: 'Maximum security garrison. Hermetic royal knights patrol the inner bailey.',
      backgroundImage: 'assets/images/world_map.jpg',
      ambientAudio: 'Trumpet calls and armored boots marching in unison...',
      connectedNodeIds: ['n3'],
      npcs: ['High Sentinel Guard', 'Ducal Emissary'],
      defaultLocked: true, // Locked initially!
      mapPos: Offset(800, 220),
    ),
  };

  final Map<String, WorldCityNode> worldNodes = const {
    'aethel_cap': WorldCityNode(
      id: 'aethel_cap',
      name: 'Bowerstone (Aethel Capital)',
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
      connectedCityIds: ['aethel_cap', 'coral_harbor', 'gilded_shore', 'island_of_skulls'],
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
    'island_of_skulls': WorldCityNode(
      id: 'island_of_skulls',
      name: 'Island of Skulls (Sandbox)',
      continent: 'Southern Ocean',
      type: WorldCityType.fort,
      pos: Offset(450, 850),
      connectedCityIds: ['riverend_port'],
      lore: 'Ominous rocky formation shrouded in mist. Double-click or enter to access the 30-Wave Sandbox Proving Grounds.',
    ),
  };

  NavigationNode? get currentLocation =>
      currentLocationId.value != null ? nodes[currentLocationId.value] : null;
  NavigationNode get currentNode => currentLocation ?? nodes.values.first;
  CityData? get currentCity =>
      currentCityId.value != null ? cities[currentCityId.value] : null;
  WorldCityNode get currentWorldCity => worldNodes[currentWorldCityId.value]!;
  WorldCityNode get selectedWorldCity => worldNodes[selectedWorldCityId.value]!;

  // --- VIEW MODE & NAVIGATION METHODS ---

  void toggleViewMode() {
    if (currentMode.value == MapViewMode.overworld) {
      if (currentCityId.value != null) {
        currentMode.value = MapViewMode.city;
      }
    } else if (currentMode.value == MapViewMode.city) {
      currentMode.value = MapViewMode.overworld;
    } else if (currentMode.value == MapViewMode.location) {
      currentMode.value = MapViewMode.city;
    }
  }

  void exitToOverworld() {
    currentMode.value = MapViewMode.overworld;
    currentLocationId.value = null;
  }

  void enterCity(String cityId) {
    if (!unlockedCityIds.contains(cityId)) {
      Get.snackbar('AREA LOCKED', 'You do not have permission or intel to enter this city yet.',
          backgroundColor: const Color(0xFF3E1212), colorText: Colors.white);
      return;
    }
    if (cities.containsKey(cityId)) {
      currentCityId.value = cityId;
      currentMode.value = MapViewMode.city;
      currentLocationId.value = null;
    } else {
      // If city doesn't have detailed street map yet, stay on overworld
      Get.snackbar('CARTOGRAPHY INCOMPLETE', 'Street map for this region is currently being charted.',
          backgroundColor: const Color(0xFF151310), colorText: Colors.amberAccent);
    }
  }

  void exitToCityStreets() {
    if (currentCityId.value != null) {
      currentMode.value = MapViewMode.city;
      currentLocationId.value = null;
    } else {
      exitToOverworld();
    }
  }

  void moveToLocation(String locationId) {
    if (!unlockedLocationIds.contains(locationId)) {
      Get.snackbar('DISTRICT LOCKED', 'This district is barred. Advance the narrative to gain access.',
          backgroundColor: const Color(0xFF3E1212), colorText: Colors.white);
      return;
    }
    if (nodes.containsKey(locationId)) {
      currentLocationId.value = locationId;
      currentMode.value = MapViewMode.location;
    }
  }

  // --- STORY UNLOCK BRIDGE ---

  void unlockLocation(String locationId) {
    if (nodes.containsKey(locationId) && !unlockedLocationIds.contains(locationId)) {
      unlockedLocationIds.add(locationId);
      final nodeName = nodes[locationId]!.title;
      Get.snackbar(
        'NEW DISTRICT DISCOVERED',
        'Cartography updated: $nodeName is now accessible.',
        backgroundColor: const Color(0xFF162516),
        colorText: const Color(0xFFD4CFC7),
        duration: const Duration(seconds: 4),
      );
    }
  }

  void unlockCity(String cityId) {
    if (worldNodes.containsKey(cityId) && !unlockedCityIds.contains(cityId)) {
      unlockedCityIds.add(cityId);
      final cityName = worldNodes[cityId]!.name;
      Get.snackbar(
        'NEW REGION UNLOCKED',
        'Overworld routes opened to: $cityName.',
        backgroundColor: const Color(0xFF162516),
        colorText: const Color(0xFFD4CFC7),
        duration: const Duration(seconds: 4),
      );
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
      if (unlockedCityIds.contains(targetId)) {
        currentWorldCityId.value = targetId;
      } else {
        Get.snackbar('ROUTE BLOCKED', 'This region is locked or under quarantine.',
            backgroundColor: const Color(0xFF3E1212), colorText: Colors.white);
      }
    }
  }

  void toggleChronicleMap() {
    isShowingMap.value = !isShowingMap.value;
  }
}
