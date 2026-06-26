class Vitals {
  int currentHp;
  int maxHp;
  int currentMana;
  int maxMana;
  int currentStamina;
  int maxStamina;
  int currentSanity;
  int maxSanity;

  Vitals({
    this.currentHp = 100,
    this.maxHp = 100,
    this.currentMana = 50,
    this.maxMana = 50,
    this.currentStamina = 100,
    this.maxStamina = 100,
    this.currentSanity = 100,
    this.maxSanity = 100,
  });

  bool get isSanityDepleted => currentSanity <= 20;

  void reset() {
    currentHp = maxHp;
    currentMana = maxMana;
    currentStamina = maxStamina;
    currentSanity = maxSanity;
  }
}
