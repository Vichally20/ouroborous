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

  void equip(ArtifactItem item) {
    switch (item.equipSlot) {
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

  void unequip(AnatomicalSlot slot) {
    switch (slot) {
      case AnatomicalSlot.head:
        head = null;
        break;
      case AnatomicalSlot.chest:
        chest = null;
        break;
      case AnatomicalSlot.leg:
        leg = null;
        break;
      case AnatomicalSlot.mainHand:
        mainHand = null;
        break;
      case AnatomicalSlot.secondaryHand:
        secondaryHand = null;
        break;
      case AnatomicalSlot.none:
        break;
    }
  }

  double get totalEquippedWeight {
    return (head?.weight ?? 0) +
        (chest?.weight ?? 0) +
        (leg?.weight ?? 0) +
        (mainHand?.weight ?? 0) +
        (secondaryHand?.weight ?? 0);
  }
}
