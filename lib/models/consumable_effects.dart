/// What each consumable does, used both in battle and from the inventory.
class ConsumableEffect {
  final int hp;
  final int stamina;
  final int sanity;
  final String flavour;

  const ConsumableEffect({this.hp = 0, this.stamina = 0, this.sanity = 0, required this.flavour});

  String get summary {
    final parts = <String>[];
    if (hp != 0) parts.add('${hp > 0 ? '+' : ''}$hp HP');
    if (stamina != 0) parts.add('${stamina > 0 ? '+' : ''}$stamina STA');
    if (sanity != 0) parts.add('${sanity > 0 ? '+' : ''}$sanity Sanity');
    return parts.join(', ');
  }

  static const Map<String, ConsumableEffect> byItemId = {
    'c1': ConsumableEffect(stamina: 50, flavour: 'You inhale the Essence of Clarity.'),
    'c2': ConsumableEffect(sanity: 10, flavour: 'You study the forbidden notes; the fog in your mind recedes.'),
    'c3': ConsumableEffect(hp: 30, flavour: 'You chew the Mandrake Root. Wounds close.'),
    'c4': ConsumableEffect(hp: 40, stamina: 40, sanity: -10, flavour: 'You shatter the Corrupted Soul Gem. Vitality rushes in.'),
  };

  static ConsumableEffect? of(String itemId) => byItemId[itemId];
}
