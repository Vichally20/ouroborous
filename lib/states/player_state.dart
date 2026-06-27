import 'package:get/get.dart';
import '../models/attributes.dart';
import '../models/character_class.dart';
import '../models/hero_character.dart';
import '../models/item.dart';
import '../models/loadout.dart';
import '../models/vitals.dart';

class PlayerState extends GetxController {
  // Roster list of characters
  final heroes = <HeroCharacter>[].obs;
  final activeHeroIndex = 0.obs;
  final hasCreatedCharacter = false.obs;

  // Active hero observables (synced to the active character for backward compatibility)
  final characterClass = PersonalityClass.warrior.obs;
  final vitals = Vitals().obs;
  late final Rx<CoreAttributes> attributes;
  final resistances = Resistances().obs;
  final loadout = AnatomicalLoadout().obs;
  final maxWeightCapacity = 50.0.obs;

  // XP Tracker Fields (Shared progress)
  final level = 1.obs;
  final currentXp = 0.obs;
  final xpToNextLevel = 100.obs;

  PlayerState() {
    // 1. Initialize Aleph the Unbound (Warrior)
    final aleph = HeroCharacter(
      id: 'aleph',
      name: 'Aleph the Unbound',
      subtitle: 'HYPERTROPHIC VANGUARD',
      characterClass: PersonalityClass.warrior,
      attributes: CoreAttributes(
        strength: 16,
        dexterity: 10,
        intelligence: 8,
        constitution: 14,
        insight: 10,
      ),
      loadout: AnatomicalLoadout(
        mainHand: const ArtifactItem(
          id: 'w1',
          name: 'Blackiron Claymore',
          description: 'Massive greatsword forged from dense meteoric iron.',
          category: ItemCategory.weapon,
          rarity: ItemRarity.relic,
          weight: 8.50,
          equipSlot: AnatomicalSlot.mainHand,
          statBonus: 18,
          count: 1,
        ),
        chest: const ArtifactItem(
          id: 'ap1',
          name: 'Scholar\'s Tattered Robes',
          description: 'Heavy academic vestments infused with alchemical fumes.',
          category: ItemCategory.apparel,
          rarity: ItemRarity.unpolished,
          weight: 3.20,
          equipSlot: AnatomicalSlot.chest,
          statBonus: 14,
          count: 1,
        ),
      ),
      vitals: Vitals(
        currentHp: 100,
        maxHp: 100,
        currentStamina: 100,
        maxStamina: 100,
      ),
      description: 'Aleph boasts hypertrophic musculature and reinforced bone density. Excellent for front-line heavy combat.',
    );

    // 2. Initialize Kaelen the Hermetic (Sorcerer)
    final kaelen = HeroCharacter(
      id: 'kaelen',
      name: 'Kaelen the Hermetic',
      subtitle: 'CEREBRAL ALCHEMIST',
      characterClass: PersonalityClass.sorcerer,
      attributes: CoreAttributes(
        strength: 8,
        dexterity: 10,
        intelligence: 18,
        constitution: 10,
        insight: 15,
      ),
      loadout: AnatomicalLoadout(
        mainHand: const ArtifactItem(
          id: 'w2_main',
          name: 'Ceremonial Athame',
          description: 'Occult dagger used to focus hermetic fire spells.',
          category: ItemCategory.weapon,
          rarity: ItemRarity.clinical,
          weight: 1.00,
          equipSlot: AnatomicalSlot.mainHand,
          statBonus: 10,
          count: 1,
        ),
        secondaryHand: const ArtifactItem(
          id: 'w2',
          name: 'Cinquedea of the Blind',
          description: 'Broad ceremonial dagger engraved with braille runes.',
          category: ItemCategory.weapon,
          rarity: ItemRarity.clinical,
          weight: 1.25,
          equipSlot: AnatomicalSlot.secondaryHand,
          statBonus: 12,
          count: 1,
        ),
      ),
      vitals: Vitals(
        currentHp: 80,
        maxHp: 80,
        currentStamina: 100,
        maxStamina: 100,
      ),
      description: 'Kaelen possesses elevated cerebral capacity coupled with a fragile skeletal frame. Specializes in magic spells.',
    );

    // 3. Initialize Lyra the Silent (Assassin)
    final lyra = HeroCharacter(
      id: 'lyra',
      name: 'Lyra the Silent',
      subtitle: 'CLINICAL EXECUTIONER',
      characterClass: PersonalityClass.assassin,
      attributes: CoreAttributes(
        strength: 10,
        dexterity: 18,
        intelligence: 12,
        constitution: 10,
        insight: 11,
      ),
      loadout: AnatomicalLoadout(
        mainHand: const ArtifactItem(
          id: 'w3',
          name: 'Weathered Shortbow',
          description: 'Yew recurve bow seasoned by ash and damp air.',
          category: ItemCategory.weapon,
          rarity: ItemRarity.common,
          weight: 2.00,
          equipSlot: AnatomicalSlot.mainHand,
          statBonus: 10,
          count: 1,
        ),
        head: const ArtifactItem(
          id: 'ap3_head',
          name: 'Assassin\'s Cowl',
          description: 'Sanitized hood designed to hide facial thermals.',
          category: ItemCategory.apparel,
          rarity: ItemRarity.clinical,
          weight: 0.80,
          equipSlot: AnatomicalSlot.head,
          statBonus: 8,
          count: 1,
        ),
      ),
      vitals: Vitals(
        currentHp: 95,
        maxHp: 95,
        currentStamina: 120,
        maxStamina: 120,
      ),
      description: 'Lyra has severed pain receptors and acute vascular precision. High stamina pool and dexterity scaling.',
    );

    heroes.addAll([aleph, kaelen, lyra]);

    // Initial binding
    attributes = CoreAttributes(
      strength: aleph.attributes.strength,
      dexterity: aleph.attributes.dexterity,
      intelligence: aleph.attributes.intelligence,
      constitution: aleph.attributes.constitution,
      insight: aleph.attributes.insight,
    ).obs;

    characterClass.value = aleph.characterClass;
    vitals.value = aleph.vitals;
    loadout.value = aleph.loadout;
  }

  void selectHero(int index) {
    if (index < 0 || index >= heroes.length) return;
    activeHeroIndex.value = index;

    final hero = heroes[index];
    characterClass.value = hero.characterClass;
    vitals.value = hero.vitals;
    loadout.value = hero.loadout;

    attributes.value = CoreAttributes(
      strength: hero.attributes.strength,
      dexterity: hero.attributes.dexterity,
      intelligence: hero.attributes.intelligence,
      constitution: hero.attributes.constitution,
      insight: hero.attributes.insight,
    );

    vitals.refresh();
    attributes.refresh();
    loadout.refresh();
  }

  void initializeCustomCharacter(String name, int chosenIndex) {
    if (chosenIndex < 0 || chosenIndex >= heroes.length) return;
    
    // Update selected hero's name and select them
    final baseHero = heroes[chosenIndex];
    final customHero = HeroCharacter(
      id: baseHero.id,
      name: name.toUpperCase(),
      subtitle: baseHero.subtitle,
      characterClass: baseHero.characterClass,
      attributes: baseHero.attributes,
      loadout: baseHero.loadout,
      vitals: baseHero.vitals,
      description: baseHero.description,
    );
    
    // Replace in heroes list
    heroes[chosenIndex] = customHero;
    
    // Select the hero
    selectHero(chosenIndex);
    
    // Mark as created
    hasCreatedCharacter.value = true;
  }

  void setClass(PersonalityClass newClass) {
    // Keep setClass for class updates, updating active hero class
    final hero = heroes[activeHeroIndex.value];
    final updatedHero = HeroCharacter(
      id: hero.id,
      name: hero.name,
      subtitle: hero.subtitle,
      characterClass: newClass,
      attributes: CoreAttributes(
        strength: newClass.baseStr,
        dexterity: newClass.baseDex,
        intelligence: newClass.baseInt,
        constitution: newClass.baseCon,
        insight: hero.attributes.insight,
      ),
      loadout: hero.loadout,
      vitals: hero.vitals,
      description: hero.description,
    );
    heroes[activeHeroIndex.value] = updatedHero;
    selectHero(activeHeroIndex.value);
  }

  bool get isEncumbered => loadout.value.totalEquippedWeight > maxWeightCapacity.value;

  void equipArtifact(ArtifactItem item) {
    loadout.value.equip(item);
    loadout.refresh();
    
    // Sync to roster copy
    final hero = heroes[activeHeroIndex.value];
    hero.loadout.equip(item);
  }

  void unequipArtifact(AnatomicalSlot slot) {
    loadout.value.unequip(slot);
    loadout.refresh();

    // Sync to roster copy
    final hero = heroes[activeHeroIndex.value];
    hero.loadout.unequip(slot);
  }

  void depleteSanity(int amount) {
    vitals.value.currentSanity -= amount;
    if (vitals.value.currentSanity < 0) vitals.value.currentSanity = 0;
    vitals.refresh();
  }

  void gainXp(int amount) {
    currentXp.value += amount;
    while (currentXp.value >= xpToNextLevel.value) {
      currentXp.value -= xpToNextLevel.value;
      level.value++;
      xpToNextLevel.value = (xpToNextLevel.value * 1.5).round();
      vitals.value.maxHp += 10;
      vitals.value.maxMana += 5;
      vitals.value.reset();
      vitals.refresh();
    }
  }
}
