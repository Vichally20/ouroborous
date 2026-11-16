/// The story's small condition and effect language, used by chapter JSON.
///
/// Conditions read like `leads >= 3 && !last_boat_burned`. A bare name is true
/// when it is a set flag or a value other than 0. Values that are never set read
/// as 0. Names may hold dots: `rep.fisherfolk`, `bond.tam`, `attr.insight`,
/// `seen.a1_cove`.
///
/// Effects are one per string:
///   `mercy +1`, `sanity -5`, `rep.fisherfolk =0`   change a value
///   `flag ran_at_once`, `unflag ran_at_once`       set or clear a flag
///   `item rusted falchion`                         give a catalogue item
///   `journal The salt works, three days north`     add a journal line
library;

/// Evaluates [condition] against [lookup]. An empty or null condition is true.
/// Throws [FormatException] on a condition that doesn't parse.
bool evaluateCondition(String? condition, int Function(String name) lookup) {
  if (condition == null || condition.trim().isEmpty) return true;
  final parser = _Parser(_tokenize(condition), lookup, condition);
  final value = parser.parseOr();
  parser.expectEnd();
  return value != 0;
}

/// Throws [FormatException] if [condition] is not valid; used to check chapter files.
void validateCondition(String condition) => evaluateCondition(condition, (_) => 0);

// ─── Tokenizer ────────────────────────────────────────────────────────────────

enum _T { number, name, op, lparen, rparen }

class _Token {
  final _T type;
  final String text;
  const _Token(this.type, this.text);
}

final _namePattern = RegExp(r'[A-Za-z_][A-Za-z0-9_.]*');
final _numberPattern = RegExp(r'-?\d+');
const _ops = ['>=', '<=', '==', '!=', '&&', '||', '>', '<', '!'];

List<_Token> _tokenize(String source) {
  final tokens = <_Token>[];
  var i = 0;
  while (i < source.length) {
    final c = source[i];
    if (c == ' ' || c == '\t') {
      i++;
      continue;
    }
    if (c == '(') {
      tokens.add(const _Token(_T.lparen, '('));
      i++;
      continue;
    }
    if (c == ')') {
      tokens.add(const _Token(_T.rparen, ')'));
      i++;
      continue;
    }
    final op = _ops.firstWhere((o) => source.startsWith(o, i), orElse: () => '');
    // A '-' followed by a digit is a negative number, not an operator.
    if (op.isNotEmpty) {
      tokens.add(_Token(_T.op, op));
      i += op.length;
      continue;
    }
    final num = _numberPattern.matchAsPrefix(source, i);
    if (num != null) {
      tokens.add(_Token(_T.number, num.group(0)!));
      i = num.end;
      continue;
    }
    final name = _namePattern.matchAsPrefix(source, i);
    if (name != null) {
      tokens.add(_Token(_T.name, name.group(0)!));
      i = name.end;
      continue;
    }
    throw FormatException('Unexpected "$c" in condition', source, i);
  }
  return tokens;
}

// ─── Parser (recursive descent; booleans are 1 and 0) ─────────────────────────

class _Parser {
  final List<_Token> tokens;
  final int Function(String) lookup;
  final String source;
  var _pos = 0;

  _Parser(this.tokens, this.lookup, this.source);

  _Token? get _peek => _pos < tokens.length ? tokens[_pos] : null;

  bool _takeOp(String op) {
    final t = _peek;
    if (t != null && t.type == _T.op && t.text == op) {
      _pos++;
      return true;
    }
    return false;
  }

  void expectEnd() {
    if (_peek != null) throw FormatException('Unexpected "${_peek!.text}" in condition', source);
  }

  int parseOr() {
    var v = parseAnd();
    while (_takeOp('||')) {
      final r = parseAnd();
      v = (v != 0 || r != 0) ? 1 : 0;
    }
    return v;
  }

  int parseAnd() {
    var v = parseUnary();
    while (_takeOp('&&')) {
      final r = parseUnary();
      v = (v != 0 && r != 0) ? 1 : 0;
    }
    return v;
  }

  int parseUnary() {
    if (_takeOp('!')) return parseUnary() == 0 ? 1 : 0;
    return parseComparison();
  }

  int parseComparison() {
    final left = parsePrimary();
    for (final op in const ['>=', '<=', '==', '!=', '>', '<']) {
      if (_takeOp(op)) {
        final right = parsePrimary();
        final result = switch (op) {
          '>=' => left >= right,
          '<=' => left <= right,
          '==' => left == right,
          '!=' => left != right,
          '>' => left > right,
          _ => left < right,
        };
        return result ? 1 : 0;
      }
    }
    return left;
  }

  int parsePrimary() {
    final t = _peek;
    if (t == null) throw FormatException('Condition ends too early', source);
    _pos++;
    switch (t.type) {
      case _T.number:
        return int.parse(t.text);
      case _T.name:
        return lookup(t.text);
      case _T.lparen:
        final v = parseOr();
        if (_peek?.type != _T.rparen) throw FormatException('Missing ")" in condition', source);
        _pos++;
        return v;
      default:
        throw FormatException('Unexpected "${t.text}" in condition', source);
    }
  }
}

// ─── Effects ─────────────────────────────────────────────────────────────────

enum StoryEffectKind { add, set, flag, unflag, item, journal }

class StoryEffect {
  final StoryEffectKind kind;

  /// Value name (`mercy`, `rep.fisherfolk`), flag name, item name or journal text.
  final String target;
  final int amount;

  const StoryEffect(this.kind, this.target, [this.amount = 0]);

  static final _valueChange = RegExp(r'^([A-Za-z_][A-Za-z0-9_.]*)\s+([+=-])\s*(\d+)$');
  static final _word = RegExp(r'^(flag|unflag|item|journal)\s+(.+)$');

  /// Parses one effect string. Throws [FormatException] when it isn't one.
  factory StoryEffect.parse(String source) {
    final s = source.trim();
    final word = _word.firstMatch(s);
    if (word != null) {
      final rest = word.group(2)!.trim();
      return switch (word.group(1)) {
        'flag' => StoryEffect(StoryEffectKind.flag, rest),
        'unflag' => StoryEffect(StoryEffectKind.unflag, rest),
        'item' => StoryEffect(StoryEffectKind.item, rest),
        _ => StoryEffect(StoryEffectKind.journal, rest),
      };
    }
    final change = _valueChange.firstMatch(s);
    if (change != null) {
      final n = int.parse(change.group(3)!);
      return switch (change.group(2)) {
        '+' => StoryEffect(StoryEffectKind.add, change.group(1)!, n),
        '-' => StoryEffect(StoryEffectKind.add, change.group(1)!, -n),
        _ => StoryEffect(StoryEffectKind.set, change.group(1)!, n),
      };
    }
    throw FormatException('Not a story effect', source);
  }
}

/// An effect list entry: a plain effect, or a group applied only when [condition] holds.
class StoryEffectEntry {
  final String? condition;
  final List<StoryEffect> effects;
  const StoryEffectEntry(this.effects, [this.condition]);

  /// Reads `"mercy +1"` or `{"if": "spared_rower", "do": ["mercy -2"]}`.
  static List<StoryEffectEntry> listFromJson(Object? json) {
    if (json == null) return const [];
    return [
      for (final e in json as List)
        if (e is String)
          StoryEffectEntry([StoryEffect.parse(e)])
        else
          StoryEffectEntry(
            [for (final s in ((e as Map)['do'] as List)) StoryEffect.parse(s as String)],
            e['if'] as String?,
          ),
    ];
  }
}

/// Limits for tracked values, by name or prefix.
int clampStoryValue(String name, int value) {
  if (name == 'mercy') return value.clamp(-10, 10);
  if (name.startsWith('rep.')) return value.clamp(-2, 2);
  if (name.startsWith('bond.')) return value.clamp(0, 5);
  if (name == 'leads') return value < 0 ? 0 : value;
  return value;
}

/// Reputation tier names, from -2 to +2.
const reputationTiers = ['Hated', 'Distrusted', 'Neutral', 'Known', 'Trusted'];
