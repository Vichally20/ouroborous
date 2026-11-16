import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/story_engine.dart';
import '../models/attributes.dart';
import '../models/character_class.dart';
import '../models/hero_character.dart';
import '../models/item.dart';
import '../models/loadout.dart';
import '../models/vitals.dart';
import 'combat_state.dart';
import 'game_controller.dart';
import 'inventory_state.dart';
import 'navigation_state.dart';
import 'player_state.dart';
import 'settings_state.dart';
import 'town_state.dart';

/// Which top-level screen the app shows.
enum AppScreen { menu, onboarding, game }

/// What a slot card shows without loading the whole save.
class SaveSlotSummary {
  final int slot;
  final String heroName;
  final PersonalityClassType classType;
  final String portrait;
  final int level;
  final String place;
  final DateTime savedAt;

  const SaveSlotSummary({
    required this.slot,
    required this.heroName,
    required this.classType,
    required this.portrait,
    required this.level,
    required this.place,
    required this.savedAt,
  });

  factory SaveSlotSummary.fromJson(int slot, Map<String, dynamic> j) => SaveSlotSummary(
        slot: slot,
        heroName: j['heroName'] as String? ?? 'Unknown',
        classType: PersonalityClassType.values.byName(j['classType'] as String? ?? 'warrior'),
        portrait: j['portrait'] as String? ?? '',
        level: j['level'] as int? ?? 1,
        place: j['place'] as String? ?? '',
        savedAt: DateTime.tryParse(j['savedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Three save slots kept in shared preferences, plus the app's menu / onboarding /
/// game switch. A running game saves itself a moment after anything that matters
/// changes (story step, district, purse, gear, vitals), but never mid-battle.
class SaveState extends GetxService {
  static const slotCount = 3;
  static const formatVersion = 1;
  static const _slotKey = 'ouroboros.slot.';
  static const _settingsKey = 'ouroboros.settings';
  static const autosaveDelay = Duration(milliseconds: 800);

  final screen = AppScreen.menu.obs;
  final slots = RxList<SaveSlotSummary?>(List<SaveSlotSummary?>.filled(slotCount, null));
  final activeSlot = RxnInt();
  final ready = false.obs;

  SharedPreferences? _prefs;
  final _workers = <Worker>[];
  Timer? _pending;

  GameController get _game => Get.find<GameController>();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _refreshSummaries();
    _restoreSettings();
    _watchSettings();
    ready.value = true;
  }

  // ─── Slots ──────────────────────────────────────────────────────────────────

  void _refreshSummaries() {
    for (var i = 0; i < slotCount; i++) {
      final raw = _prefs?.getString('$_slotKey$i');
      SaveSlotSummary? summary;
      if (raw != null) {
        try {
          summary = SaveSlotSummary.fromJson(i, (jsonDecode(raw) as Map<String, dynamic>)['summary'] as Map<String, dynamic>);
        } catch (_) {
          summary = null; // unreadable save: treat the slot as empty
        }
      }
      slots[i] = summary;
    }
  }

  bool get hasAnySave => slots.any((s) => s != null);

  /// The slot saved most recently, for CONTINUE.
  int? get latestSlot {
    SaveSlotSummary? best;
    for (final s in slots) {
      if (s != null && (best == null || s.savedAt.isAfter(best.savedAt))) best = s;
    }
    return best?.slot;
  }

  int? get firstEmptySlot {
    for (var i = 0; i < slotCount; i++) {
      if (slots[i] == null) return i;
    }
    return null;
  }

  // ─── Game lifecycle ─────────────────────────────────────────────────────────

  /// Blank playthrough bound to [slot]; the player picks a hero next.
  void startNewGame(int slot) {
    _stopWatching();
    _game.resetSession();
    activeSlot.value = slot;
    screen.value = AppScreen.onboarding;
  }

  /// Finishes onboarding: names the chosen hero, writes the first save and enters the game.
  Future<void> beginChronicle({required String name, required int heroIndex, required String portrait}) async {
    Get.find<PlayerState>().initializeCustomCharacter(name, heroIndex, portrait: portrait);
    screen.value = AppScreen.game;
    await saveNow();
    _watchGame();
  }

  /// Loads [slot] onto a fresh session. Returns null on success or why it failed.
  Future<String?> load(int slot) async {
    final raw = _prefs?.getString('$_slotKey$slot');
    if (raw == null) return 'That slot is empty.';
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return 'That save is damaged and cannot be read.';
    }
    _stopWatching();
    _game.resetSession();
    try {
      await _apply(data);
    } catch (e) {
      _game.resetSession();
      return 'That save could not be loaded.';
    }
    activeSlot.value = slot;
    screen.value = AppScreen.game;
    _watchGame();
    return null;
  }

  /// Reloads this game's slot: back to the last checkpoint, e.g. after a lost battle.
  /// Battles are never saved, so this is the moment before the fight was taken.
  /// Returns null on success, or why it couldn't (no slot, damaged save).
  Future<String?> restoreCheckpoint() async {
    final slot = activeSlot.value;
    if (slot == null) return 'There is no saved checkpoint for this game.';
    return load(slot);
  }

  /// Saves now and goes back to the main menu.
  Future<void> returnToMenu() async {
    if (screen.value == AppScreen.game) await saveNow();
    _stopWatching();
    screen.value = AppScreen.menu;
  }

  /// Leaves onboarding without starting; the slot stays as it was.
  void cancelNewGame() {
    activeSlot.value = null;
    screen.value = AppScreen.menu;
  }

  Future<void> deleteSlot(int slot) async {
    await _prefs?.remove('$_slotKey$slot');
    if (activeSlot.value == slot) activeSlot.value = null;
    _refreshSummaries();
  }

  /// Deletes every slot. A game in progress ends and the app returns to the menu.
  Future<void> wipeAll() async {
    _stopWatching();
    for (var i = 0; i < slotCount; i++) {
      await _prefs?.remove('$_slotKey$i');
    }
    activeSlot.value = null;
    _refreshSummaries();
    if (screen.value != AppScreen.menu) screen.value = AppScreen.menu;
  }

  /// Writes the running game to its slot. Skipped while a battle is on.
  Future<bool> saveNow() async {
    final slot = activeSlot.value;
    if (slot == null || _prefs == null) return false;
    if (Get.isRegistered<CombatController>() && Get.find<CombatController>().inCombat.value) return false;
    if (!Get.find<PlayerState>().hasCreatedCharacter.value) return false;
    _pending?.cancel();
    final ok = await _prefs!.setString('$_slotKey$slot', jsonEncode(snapshot()));
    _refreshSummaries();
    return ok;
  }

  // ─── Autosave ───────────────────────────────────────────────────────────────

  void _watchGame() {
    _stopWatching();
    final player = Get.find<PlayerState>();
    final nav = Get.find<NavigationState>();
    _workers.add(everAll([
      Get.find<StoryEngine>().currentNode,
      Get.find<StoryEngine>().flags,
      Get.find<StoryEngine>().values,
      nav.presentLocationId,
      nav.currentWorldCityId,
      nav.unlockedLocationIds,
      nav.unlockedCityIds,
      Get.find<InventoryState>().ledger,
      Get.find<TownState>().bankedCrowns,
      player.heroes,
      player.vitals,
      player.loadout,
      player.level,
      player.activeHeroIndex,
      Get.find<CombatController>().inCombat,
    ], (_) => _scheduleSave()));
  }

  void _stopWatching() {
    _pending?.cancel();
    for (final w in _workers) {
      w.dispose();
    }
    _workers.clear();
  }

  void _scheduleSave() {
    _pending?.cancel();
    _pending = Timer(autosaveDelay, saveNow);
  }

  @override
  void onClose() {
    _stopWatching();
    super.onClose();
  }

  // ─── Snapshot ───────────────────────────────────────────────────────────────

  Map<String, dynamic> snapshot() {
    final player = Get.find<PlayerState>();
    final inv = Get.find<InventoryState>();
    final nav = Get.find<NavigationState>();
    final story = Get.find<StoryEngine>();
    final town = Get.find<TownState>();
    final hero = player.activeHero;
    final present = nav.nodes[nav.presentLocationId.value];
    final city = nav.worldNodes[nav.currentWorldCityId.value];

    return {
      'v': formatVersion,
      'summary': {
        'heroName': hero.name,
        'classType': hero.characterClass.type.name,
        'portrait': hero.portrait,
        'level': player.level.value,
        // Where the story is (the scene), else where the map says you stand.
        'place': story.currentNode.value != null
            ? _titleCase(story.currentNode.value!.title)
            : (present != null && present.cityId == nav.currentWorldCityId.value ? present.title : (city?.name ?? '')),
        'savedAt': DateTime.now().toIso8601String(),
      },
      'player': {
        'activeHeroIndex': player.activeHeroIndex.value,
        'level': player.level.value,
        'xp': player.currentXp.value,
        'xpToNext': player.xpToNextLevel.value,
        'heroes': [for (final h in player.heroes) _heroToJson(h)],
      },
      'inventory': [for (final i in inv.ledger) i.toJson()],
      'town': {'banked': town.bankedCrowns.value},
      'nav': {
        'unlockedLocations': nav.unlockedLocationIds.toList(),
        'unlockedCities': nav.unlockedCityIds.toList(),
        'worldCity': nav.currentWorldCityId.value,
        'present': nav.presentLocationId.value,
      },
      'story': {
        'chapter': story.currentChapterId.value,
        'node': story.currentNode.value?.id,
        'visited': story.visitedNodeIds.toList(),
        'completed': story.completedChapterIds.toList(),
        'claimed': story.claimedLootNodeIds.toList(),
        'flags': story.flags.toList(),
        'values': Map<String, int>.from(story.values),
        'journal': story.journal.toList(),
      },
    };
  }

  /// "THE COVE AT DUSK" → "The Cove at Dusk".
  static String _titleCase(String s) {
    const small = {'a', 'an', 'and', 'at', 'of', 'the', 'to', 'in', 'on'};
    final words = s.toLowerCase().split(' ');
    return [
      for (final (i, w) in words.indexed)
        i > 0 && small.contains(w) || w.isEmpty ? w : w[0].toUpperCase() + w.substring(1),
    ].join(' ');
  }

  Map<String, dynamic> _heroToJson(HeroCharacter h) => {
        'id': h.id,
        'name': h.name,
        'classType': h.characterClass.type.name,
        'portrait': h.portrait,
        'talents': h.unlockedTalents.toList(),
        'attributes': {
          'str': h.attributes.strength,
          'dex': h.attributes.dexterity,
          'int': h.attributes.intelligence,
          'con': h.attributes.constitution,
          'ins': h.attributes.insight,
        },
        'vitals': {
          'hp': h.vitals.currentHp,
          'maxHp': h.vitals.maxHp,
          'mana': h.vitals.currentMana,
          'maxMana': h.vitals.maxMana,
          'sta': h.vitals.currentStamina,
          'maxSta': h.vitals.maxStamina,
          'san': h.vitals.currentSanity,
          'maxSan': h.vitals.maxSanity,
        },
        'loadout': {
          for (final slot in AnatomicalSlot.values)
            if (h.loadout.itemIn(slot) case final item?) slot.name: item.toJson(),
        },
      };

  static PersonalityClass _classOf(PersonalityClassType t) => switch (t) {
        PersonalityClassType.warrior => PersonalityClass.warrior,
        PersonalityClassType.sorcerer => PersonalityClass.sorcerer,
        PersonalityClassType.assassin => PersonalityClass.assassin,
      };

  Future<void> _apply(Map<String, dynamic> data) async {
    final player = Get.find<PlayerState>();
    final inv = Get.find<InventoryState>();
    final nav = Get.find<NavigationState>();
    final town = Get.find<TownState>();

    // Heroes: start from the roster entry (subtitle, description, skills) and lay the save over it.
    final p = data['player'] as Map<String, dynamic>;
    final saved = (p['heroes'] as List).cast<Map<String, dynamic>>();
    for (final h in saved) {
      final index = player.heroes.indexWhere((b) => b.id == h['id']);
      if (index < 0) continue;
      final base = player.heroes[index];
      final cls = _classOf(PersonalityClassType.values.byName(h['classType'] as String));
      final a = h['attributes'] as Map<String, dynamic>;
      final v = h['vitals'] as Map<String, dynamic>;
      final l = (h['loadout'] as Map<String, dynamic>).map(
          (k, item) => MapEntry(AnatomicalSlot.values.byName(k), ArtifactItem.fromJson(item as Map<String, dynamic>)));
      player.heroes[index] = HeroCharacter(
        id: base.id,
        name: h['name'] as String,
        subtitle: base.subtitle,
        characterClass: cls,
        attributes: CoreAttributes(
          strength: a['str'] as int,
          dexterity: a['dex'] as int,
          intelligence: a['int'] as int,
          constitution: a['con'] as int,
          insight: a['ins'] as int,
        ),
        loadout: AnatomicalLoadout(
          head: l[AnatomicalSlot.head],
          chest: l[AnatomicalSlot.chest],
          leg: l[AnatomicalSlot.leg],
          mainHand: l[AnatomicalSlot.mainHand],
          secondaryHand: l[AnatomicalSlot.secondaryHand],
        ),
        vitals: Vitals(
          currentHp: v['hp'] as int,
          maxHp: v['maxHp'] as int,
          currentMana: v['mana'] as int,
          maxMana: v['maxMana'] as int,
          currentStamina: v['sta'] as int,
          maxStamina: v['maxSta'] as int,
          currentSanity: v['san'] as int,
          maxSanity: v['maxSan'] as int,
        ),
        description: base.description,
        availableSkills: cls.type == base.characterClass.type ? base.availableSkills : null,
        unlockedTalents: (h['talents'] as List).cast<String>().toSet(),
        portrait: h['portrait'] as String?,
      );
    }
    player.level.value = p['level'] as int;
    player.currentXp.value = p['xp'] as int;
    player.xpToNextLevel.value = p['xpToNext'] as int;
    player.hasCreatedCharacter.value = true;
    player.selectHero((p['activeHeroIndex'] as int).clamp(0, player.heroes.length - 1));
    player.heroes.refresh();

    inv.ledger.assignAll([
      for (final i in (data['inventory'] as List).cast<Map<String, dynamic>>()) ArtifactItem.fromJson(i),
    ]);

    town.bankedCrowns.value = (data['town'] as Map<String, dynamic>)['banked'] as int? ?? 0;

    final n = data['nav'] as Map<String, dynamic>;
    nav.unlockedLocationIds.assignAll((n['unlockedLocations'] as List).cast<String>().where(nav.nodes.containsKey));
    nav.unlockedCityIds.assignAll((n['unlockedCities'] as List).cast<String>().where(nav.worldNodes.containsKey));
    final world = n['worldCity'] as String?;
    if (world != null && nav.worldNodes.containsKey(world)) {
      nav.currentWorldCityId.value = world;
      nav.selectedWorldCityId.value = world;
    }
    final present = n['present'] as String?;
    if (present != null && nav.nodes.containsKey(present)) nav.presentLocationId.value = present;

    final s = data['story'] as Map<String, dynamic>;
    await Get.find<StoryEngine>().restore(
      chapterId: s['chapter'] as String? ?? '',
      nodeId: s['node'] as String?,
      visited: (s['visited'] as List).cast<String>(),
      completed: (s['completed'] as List).cast<String>(),
      claimed: (s['claimed'] as List).cast<String>(),
      flags: (s['flags'] as List? ?? const []).cast<String>(),
      values: (s['values'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      journal: (s['journal'] as List? ?? const []).cast<String>(),
    );
  }

  // ─── Settings ───────────────────────────────────────────────────────────────

  void _restoreSettings() {
    final raw = _prefs?.getString(_settingsKey);
    if (raw == null || !Get.isRegistered<SettingsState>()) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final s = Get.find<SettingsState>();
      s.masterVolume.value = (j['volume'] as num?)?.toDouble() ?? s.masterVolume.value;
      s.textSpeed.value = TextSpeedOption.values.byName(j['textSpeed'] as String? ?? s.textSpeed.value.name);
      s.screenShake.value = j['shake'] as bool? ?? s.screenShake.value;
      s.attackDelay.value = (j['attackDelay'] as num?)?.toDouble() ?? s.attackDelay.value;
    } catch (_) {}
  }

  void _watchSettings() {
    if (!Get.isRegistered<SettingsState>()) return;
    final s = Get.find<SettingsState>();
    everAll([s.masterVolume, s.textSpeed, s.screenShake, s.attackDelay], (_) {
      _prefs?.setString(
          _settingsKey,
          jsonEncode({
            'volume': s.masterVolume.value,
            'textSpeed': s.textSpeed.value.name,
            'shake': s.screenShake.value,
            'attackDelay': s.attackDelay.value,
          }));
    });
  }
}
