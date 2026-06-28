class CoreAttributes {
  int strength;
  int dexterity;
  int intelligence;
  int constitution;
  int insight;

  CoreAttributes({
    this.strength = 10,
    this.dexterity = 10,
    this.intelligence = 10,
    this.constitution = 10,
    this.insight = 10,
  });

  bool checkAttribute(String attr, int requirement) {
    return getAttributeValue(attr) >= requirement;
  }

  int getAttributeValue(String attr) {
    switch (attr.toUpperCase()) {
      case 'STR':
      case 'STRENGTH':
        return strength;
      case 'DEX':
      case 'DEXTERITY':
        return dexterity;
      case 'INT':
      case 'INTELLIGENCE':
        return intelligence;
      case 'CON':
      case 'CONSTITUTION':
        return constitution;
      case 'INSIGHT':
        return insight;
      default:
        return 0;
    }
  }
}

class Resistances {
  int physical;
  int bleed;
  int poison;
  int madness;

  Resistances({
    this.physical = 10,
    this.bleed = 15,
    this.poison = 5,
    this.madness = 0,
  });
}
