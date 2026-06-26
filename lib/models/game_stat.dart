class GameStat {
  int score;
  int health;
  int maxHealth;
  int distance;

  GameStat({
    this.score = 0,
    this.health = 100,
    this.maxHealth = 100,
    this.distance = 0,
  });

  void reset() {
    score = 0;
    health = maxHealth;
    distance = 0;
  }
}
