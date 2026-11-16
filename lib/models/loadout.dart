import 'item.dart';

class AnatomicalLoadout {
  ArtifactItem? head;
  ArtifactItem? chest;
  ArtifactItem? leg;
  ArtifactItem? mainHand;
  ArtifactItem? secondaryHand;

  AnatomicalLoadout({
    this.head,
    this.chest,
    this.leg,
    this.mainHand,
    this.secondaryHand,
  });

  ArtifactItem? itemIn(AnatomicalSlot slot) {
    switch (slot) {
      case AnatomicalSlot.head:
        return head;
      case AnatomicalSlot.chest:
        return chest;
      case AnatomicalSlot.leg:
        return leg;
      case AnatomicalSlot.mainHand:
        return mainHand;
      case AnatomicalSlot.secondaryHand:
        return secondaryHand;
      case AnatomicalSlot.none:
        return null;
    }
  }

  void _set(AnatomicalSlot slot, ArtifactItem? item) {
    switch (slot) {
      case AnatomicalSlot.head:
        head = item;
        break;
      case AnatomicalSlot.chest:
        chest = item;
        break;
      case AnatomicalSlot.leg:
        leg = item;
        break;
      case AnatomicalSlot.mainHand:
        mainHand = item;
        break;
      case AnatomicalSlot.secondaryHand:
        secondaryHand = item;
        break;
      case AnatomicalSlot.none:
        break;
    }
  }

  /// Puts [item] in its slot (a single copy) and returns everything it displaced,
  /// so the caller can return those items to the inventory. A two-handed weapon
  /// also clears the secondary hand, and an off-hand item clears a two-handed main hand.
  List<ArtifactItem> equip(ArtifactItem item) {
    final slot = item.equipSlot;
    if (slot == AnatomicalSlot.none) return const [];

    final displaced = <ArtifactItem>[];
    final current = itemIn(slot);
    if (current != null) displaced.add(current);

    if (slot == AnatomicalSlot.mainHand && item.twoHanded && secondaryHand != null) {
      displaced.add(secondaryHand!);
      secondaryHand = null;
    }
    if (slot == AnatomicalSlot.secondaryHand && (mainHand?.twoHanded ?? false)) {
      displaced.add(mainHand!);
      mainHand = null;
    }

    _set(slot, item.copyWith(count: 1));
    return displaced;
  }

  /// Empties [slot] and returns what was in it.
  ArtifactItem? unequip(AnatomicalSlot slot) {
    final current = itemIn(slot);
    _set(slot, null);
    return current;
  }

  List<ArtifactItem> get equipped =>
      [head, chest, leg, mainHand, secondaryHand].whereType<ArtifactItem>().toList();

  double get totalEquippedWeight => equipped.fold(0.0, (sum, i) => sum + i.weight);
}
