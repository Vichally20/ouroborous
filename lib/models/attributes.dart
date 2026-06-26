class CoreAttributes {
  int strength;
  int dexterity;
  int intelligence;
  int constitution;

  CoreAttributes({
    this.strength = 10,
    this.dexterity = 10,
    this.intelligence = 10,
    this.constitution = 10,
  });

  bool checkAttribute(String attr, int requirement) {
    switch (attr.toUpperCase()) {
      case 'STR':
        return strength >= requirement;
      case 'DEX':
        return dexterity >= requirement;
      case 'INT':
        return intelligence >= requirement;
      case 'CON':
        return constitution >= requirement;
      default:
        return false;
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
