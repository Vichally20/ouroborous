import 'package:flutter/foundation.dart';
import '../models/attributes.dart';
import '../models/character_class.dart';
import '../models/item.dart';
import '../models/loadout.dart';
import '../models/vitals.dart';

class PlayerState extends ChangeNotifier {
  PersonalityClass _characterClass = PersonalityClass.warrior;
  final Vitals vitals = Vitals();
  late CoreAttributes attributes;
  final Resistances resistances = Resistances();
  final AnatomicalLoadout loadout = AnatomicalLoadout();
  final double maxWeightCapacity = 50.0;

  // XP Tracker Fields
  int level = 1;
  int currentXp = 0;
  int xpToNextLevel = 100;

  PlayerState() {
    _initializeAttributes();
  }

  PersonalityClass get characterClass => _characterClass;

  void _initializeAttributes() {
    attributes = CoreAttributes(
      strength: _characterClass.baseStr,
      dexterity: _characterClass.baseDex,
      intelligence: _characterClass.baseInt,
      constitution: _characterClass.baseCon,
    );
  }

  void setClass(PersonalityClass newClass) {
    _characterClass = newClass;
    _initializeAttributes();
    vitals.reset();
    notifyListeners();
  }

  bool get isEncumbered => loadout.totalEquippedWeight > maxWeightCapacity;

  void equipArtifact(ArtifactItem item) {
    loadout.equip(item);
    notifyListeners();
  }

  void unequipArtifact(AnatomicalSlot slot) {
    loadout.unequip(slot);
    notifyListeners();
  }

  void depleteSanity(int amount) {
    vitals.currentSanity -= amount;
    if (vitals.currentSanity < 0) vitals.currentSanity = 0;
    notifyListeners();
  }

  void gainXp(int amount) {
    currentXp += amount;
    while (currentXp >= xpToNextLevel) {
      currentXp -= xpToNextLevel;
      level++;
      xpToNextLevel = (xpToNextLevel * 1.5).round();
      // Level up bonus
      vitals.maxHp += 10;
      vitals.maxMana += 5;
      vitals.reset();
    }
    notifyListeners();
  }
}
