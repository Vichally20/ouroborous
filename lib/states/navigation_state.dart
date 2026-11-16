import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/widgets/toast.dart';

enum MapViewMode { overworld, city, location, tactical }

enum WorldCityType { capital, port, fort, tradeCity }

/// What an NPC can do for you (see TownState and the service sheets).
enum TownService { temper, buyGear, bank, exchange, rest, drink }

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

  /// NPCs who offer a service, by name.
  final Map<String, TownService> npcServices;
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
    this.npcServices = const {},
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
  /// Filled from each district's `defaultLocked` flag in [onInit].
  final unlockedLocationIds = <String>{}.obs;

  /// The district the hero is standing in (marked "You are here" on the city map).
  final presentLocationId = RxnString('undercroft');

  final Map<String, CityData> cities = const {
    'aethel_cap': CityData(
      id: 'aethel_cap',
      name: 'Bowerstone (Aethel Capital)',
      iconImage: 'assets/images/maps/world_aethelgard.webp',
      streetMapImage: 'assets/images/maps/bowerstone.webp', // Grand Map of Bowerstone
      defaultLocked: false,
      locationNodes: ['undercroft', 'n1', 'n2', 'n3', 'slums', 'inn', 'market', 'forge', 'bank', 'docks', 'keep'],
    ),
  };

  final Map<String, NavigationNode> nodes = const {
    'undercroft': NavigationNode(
      id: 'undercroft',
      cityId: 'aethel_cap',
      title: 'The Undercroft Entrance',
      description: 'A damp subterranean chamber smelling of old earth and sacrificial blood beneath East Gate.',
      territoryIntel: 'Monolithic black stone altar. Rhythmic clicking echoing from the shadows.',
      backgroundImage: 'assets/images/locations/undercroft.webp',
      ambientAudio: 'Rhythmic clicking echoing from deep shadows...',
      connectedNodeIds: ['n1', 'slums', 'inn'],
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
      backgroundImage: 'assets/images/locations/scriptorium.webp',
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
      backgroundImage: 'assets/images/locations/scribe_cobblestones.webp',
      ambientAudio: 'Distant clinking of glasses and rain dripping on stone...',
      connectedNodeIds: ['n1', 'market', 'bank'],
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
      backgroundImage: 'assets/images/locations/cartography_vault.webp',
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
      backgroundImage: 'assets/images/locations/shambles.webp',
      ambientAudio: 'Crowd chatter, coughing, and creaking timber...',
      connectedNodeIds: ['undercroft', 'market', 'docks', 'forge', 'inn'],
      npcs: ['Beggar Informant', 'Scavenger Merchant'],
      defaultLocked: false,
      mapPos: Offset(1300, 780),
    ),
    'inn': NavigationNode(
      id: 'inn',
      cityId: 'aethel_cap',
      title: 'The Drowned Lantern Inn',
      description: 'A crooked, smoke-stained lodging house in the Shambles where dockhands, beggars and sellswords sleep three to a pallet.',
      territoryIntel: 'Cheap beds and no questions. Rest heals the whole party; the bar serves ale for the nerves and stew for the wounds.',
      backgroundImage: 'assets/images/locations/inn.webp',
      ambientAudio: 'Snoring through thin walls, a fiddle out of tune and stew bubbling on the hearth...',
      connectedNodeIds: ['slums', 'undercroft'],
      npcs: ['Widow Marrow, Innkeeper', 'Barmaid Tess'],
      npcServices: {'Widow Marrow, Innkeeper': TownService.rest, 'Barmaid Tess': TownService.drink},
      defaultLocked: false,
      mapPos: Offset(1390, 620),
    ),
    'market': NavigationNode(
      id: 'market',
      cityId: 'aethel_cap',
      title: 'The Grand Bazaar (High Street)',
      description: 'The bustling commercial heart of Bowerstone filled with exotic goods and armorers.',
      territoryIntel: 'Heavily guarded trade hub. Prime location for weapon upgrades and rare potions.',
      backgroundImage: 'assets/images/locations/bazaar.webp',
      ambientAudio: 'Vendors shouting prices and coins clinking...',
      connectedNodeIds: ['slums', 'n2', 'docks', 'forge', 'bank'],
      npcs: ['Potion Seller', 'Silk Merchant'],
      defaultLocked: true, // Locked initially!
      mapPos: Offset(1000, 680),
    ),
    'forge': NavigationNode(
      id: 'forge',
      cityId: 'aethel_cap',
      title: 'The Ashen Anvil Forge',
      description: 'A soot-black smithy on the High Street where the bellows never rest and blades are quenched in brine.',
      territoryIntel: 'Master-forged steel. Arms and armour can be tempered up to three times, and unwanted gear sold.',
      backgroundImage: 'assets/images/locations/forge.webp',
      ambientAudio: 'Hammer on anvil, roaring bellows and the hiss of quenched steel...',
      connectedNodeIds: ['market', 'slums'],
      npcs: ['Master Blacksmith', 'Soot-Faced Apprentice'],
      npcServices: {'Master Blacksmith': TownService.temper, 'Soot-Faced Apprentice': TownService.buyGear},
      defaultLocked: false,
      mapPos: Offset(1130, 600),
    ),
    'bank': NavigationNode(
      id: 'bank',
      cityId: 'aethel_cap',
      title: 'The Serpent-Seal Counting House',
      description: 'A marble-fronted bank on the High Street where Ouroboros Crowns are weighed, lent and locked away.',
      territoryIntel: 'Iron vaults below street level. Banked crowns earn interest and are never lost in a retreat.',
      backgroundImage: 'assets/images/locations/bank.webp',
      ambientAudio: 'Coins counted on brass scales and the scratch of ledger quills...',
      connectedNodeIds: ['market', 'n2'],
      npcs: ['Chief Moneylender', 'Vault Warden'],
      npcServices: {'Chief Moneylender': TownService.bank, 'Vault Warden': TownService.exchange},
      defaultLocked: false,
      mapPos: Offset(870, 560),
    ),
    'docks': NavigationNode(
      id: 'docks',
      cityId: 'aethel_cap',
      title: 'Silverflow Docks & Rusty Anchor',
      description: 'Misty riverfront piers where smuggler vessels dock beside waterfront taverns.',
      territoryIntel: 'Smuggler territory. Naval patrol shifts change every three hours.',
      backgroundImage: 'assets/images/locations/docks.webp',
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
      backgroundImage: 'assets/images/locations/keep.webp',
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
      pos: Offset(510, 560),
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
      pos: Offset(640, 330),
      connectedCityIds: ['aethel_cap', 'skaldic_holds'],
      lore: 'Immovable northern fortress carved from glacial ice and ancient wyvern bone.',
    ),
    'skaldic_holds': WorldCityNode(
      id: 'skaldic_holds',
      name: 'Skaldic Holds',
      continent: 'Tharun',
      type: WorldCityType.fort,
      pos: Offset(400, 430),
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
      pos: Offset(1147, 373),
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
      pos: Offset(405, 655),
      connectedCityIds: ['riverend_port'],
      lore: 'Ominous rocky formation shrouded in mist. Double-click or enter to access the 30-Wave Sandbox Proving Grounds.',
    ),
  };

  NavigationNode? get currentLocation =>
      currentLocationId.value != null ? nodes[currentLocationId.value] : null;
  NavigationNode get currentNode =>
      currentLocation ?? (presentLocationId.value != null ? nodes[presentLocationId.value] : null) ?? nodes.values.first;

  @override
  void onInit() {
    super.onInit();
    unlockedLocationIds.addAll(nodes.values.where((n) => !n.defaultLocked).map((n) => n.id));
  }

  /// Title for the app bar while a map is open.
  String get mapTitle {
    switch (currentMode.value) {
      case MapViewMode.overworld:
      case MapViewMode.tactical:
        return 'The Known World';
      case MapViewMode.city:
        return currentCity?.name ?? 'City Streets';
      case MapViewMode.location:
        return currentLocation?.title ?? 'District';
    }
  }

  /// Whether a city has a street map to enter.
  bool isCharted(String cityId) => cities.containsKey(cityId);

  /// Shortest route from the current city to [targetId] through unlocked cities,
  /// excluding the start. Empty when there's no route (or you're already there).
  List<String> routeTo(String targetId) {
    final start = currentWorldCityId.value;
    if (start == targetId || !unlockedCityIds.contains(targetId)) return const [];
    final prev = <String, String>{};
    final queue = Queue<String>()..add(start);
    final seen = {start};
    while (queue.isNotEmpty) {
      final id = queue.removeFirst();
      if (id == targetId) break;
      for (final next in worldNodes[id]?.connectedCityIds ?? const <String>[]) {
        if (seen.contains(next) || !unlockedCityIds.contains(next)) continue;
        seen.add(next);
        prev[next] = id;
        queue.add(next);
      }
    }
    if (!prev.containsKey(targetId)) return const [];
    final path = <String>[];
    for (String? at = targetId; at != null && at != start; at = prev[at]) {
      path.insert(0, at);
    }
    return path;
  }
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

  /// Enter the streets of the city you're in. Returns a message when you can't.
  String? enterCity(String cityId) {
    if (!unlockedCityIds.contains(cityId)) return 'You have no way into this city yet.';
    if (currentWorldCityId.value != cityId) return 'Travel there first.';
    if (!isCharted(cityId)) return 'Its streets have not been charted yet.';
    currentCityId.value = cityId;
    currentMode.value = MapViewMode.city;
    currentLocationId.value = null;
    return null;
  }

  void exitToCityStreets() {
    if (currentCityId.value != null) {
      currentMode.value = MapViewMode.city;
      currentLocationId.value = null;
    } else {
      exitToOverworld();
    }
  }

  /// Go to an unlocked district. Returns a message when you can't.
  String? moveToLocation(String locationId) {
    final node = nodes[locationId];
    if (node == null) return 'Unknown district.';
    if (!unlockedLocationIds.contains(locationId)) return '${node.title} is barred for now.';
    currentLocationId.value = locationId;
    presentLocationId.value = locationId;
    currentMode.value = MapViewMode.location;
    return null;
  }

  // --- STORY UNLOCK BRIDGE ---

  /// Shows an unlock notice when a screen is up (skipped in headless tests).
  void _announce(String title, String message,
      {Color? backgroundColor, Color? colorText, Duration duration = const Duration(seconds: 3)}) {
    if (Get.overlayContext == null) return;
    showToast(title, message, tone: ToastTone.success, duration: duration);
  }

  void unlockLocation(String locationId) {
    if (nodes.containsKey(locationId) && !unlockedLocationIds.contains(locationId)) {
      unlockedLocationIds.add(locationId);
      final nodeName = nodes[locationId]!.title;
      _announce(
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
      _announce(
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

  /// Travels to the selected city along the shortest route through unlocked cities.
  /// Returns the cities passed through, or null when there's no route.
  List<String>? travelToSelectedCity() {
    final targetId = selectedWorldCityId.value;
    final path = routeTo(targetId);
    if (path.isEmpty) return null;
    currentWorldCityId.value = targetId;
    return path;
  }

  void toggleChronicleMap() {
    isShowingMap.value = !isShowingMap.value;
  }
}
