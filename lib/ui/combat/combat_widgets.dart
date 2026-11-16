import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/combat_models.dart';

/// Colours for the combat screen, taken from the Vitruvian Shadow design system tokens.
class CombatPalette {
  static const ground = Color(0xFF050505);
  static const chrome = Color(0xFF0C0A08);
  static const surface = Color(0xFF100E0C);
  static const raised = Color(0xFF151310);
  static const sunk = Color(0xFF080605);
  static const hairline = Color(0xFF2A2218);
  static const hairlineStrong = Color(0xFF3A2C20);
  static const bone = VitruvianColors.agedBone;
  static const parchment = Color(0xFFE0C8B0);
  static const ash = Color(0xFF8A7A68);
  static const sepia = VitruvianColors.sepiaUmber;
  static const brass = Color(0xFFC89B5D);
  static const rust = VitruvianColors.rustBlood;
  static const blood = Color(0xFF8B0000);
  static const bloodTrough = Color(0xFF220A0A);
  static const wound = Color(0xFFE0604C);
  static const stamina = Color(0xFFA08A2A);
  static const lapis = Color(0xFF6F8FB3);
  static const verdigris = Color(0xFF6FA197);
  static const defeatWash = Color(0xFF330B0B);
  static const bleed = Color(0xFFC0392B);
  static const poison = Color(0xFF8FA64A);
}

// ─── Status sigils ───────────────────────────────────────────────────────────

enum StatusKind { bleed, poison, guard }

class StatusMark {
  final StatusKind kind;
  final int stacks;
  const StatusMark(this.kind, [this.stacks = 0]);
}

/// Engraved status marker with a stack count: drop = bleed, bubbles = poison, shield = guard.
/// Each status has its own silhouette so it never relies on colour alone.
class StatusSigil extends StatelessWidget {
  final StatusMark mark;
  const StatusSigil(this.mark, {super.key});

  Color get _color => switch (mark.kind) {
        StatusKind.bleed => CombatPalette.bleed,
        StatusKind.poison => CombatPalette.poison,
        StatusKind.guard => CombatPalette.brass,
      };

  String get _label => switch (mark.kind) {
        StatusKind.bleed => 'Bleeding: ${mark.stacks} stacks, ${mark.stacks * 4} damage next turn',
        StatusKind.poison => 'Poisoned: ${mark.stacks} stacks, ${mark.stacks * 3} damage next turn',
        StatusKind.guard => 'Guarding: incoming damage halved',
      };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _label,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: CombatPalette.sunk,
                border: Border.all(color: _color),
              ),
              padding: const EdgeInsets.all(3),
              child: CustomPaint(painter: _SigilPainter(mark.kind, _color), size: const Size(14, 14)),
            ),
            if (mark.stacks > 0)
              Positioned(
                right: -5,
                bottom: -6,
                child: Container(
                  color: CombatPalette.ground,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text('${mark.stacks}',
                      style: VitruvianTypography.monospaceData(fontSize: 10, color: _color, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SigilPainter extends CustomPainter {
  final StatusKind kind;
  final Color color;
  _SigilPainter(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()..color = color;
    canvas.save();
    canvas.scale(s);
    switch (kind) {
      case StatusKind.bleed:
        final p = Path()
          ..moveTo(12, 2)
          ..cubicTo(8.5, 7.5, 5, 11.2, 5, 15)
          ..arcToPoint(const Offset(19, 15), radius: const Radius.circular(7), clockwise: false)
          ..cubicTo(19, 11.2, 15.5, 7.5, 12, 2)
          ..close();
        canvas.drawPath(p, paint);
        break;
      case StatusKind.poison:
        canvas.drawCircle(const Offset(8, 15), 4.5, paint);
        canvas.drawCircle(const Offset(15.5, 8), 3.5, paint);
        canvas.drawCircle(const Offset(17.5, 17.5), 2.5, paint);
        break;
      case StatusKind.guard:
        final p = Path()
          ..moveTo(12, 1.8)
          ..lineTo(20.5, 5)
          ..lineTo(20.5, 11.4)
          ..cubicTo(20.5, 16.6, 16.9, 20.7, 12, 22.4)
          ..cubicTo(7.1, 20.7, 3.5, 16.6, 3.5, 11.4)
          ..lineTo(3.5, 5)
          ..close();
        canvas.drawPath(p, paint);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SigilPainter old) => old.kind != kind || old.color != color;
}

// ─── HP / stamina bar with a lagging chip trail ──────────────────────────────

/// The fill drops instantly; a pale lag layer drains after it over 600ms so every
/// hit is readable. Ruled ticks every 10% read like a ledger.
class LagBar extends StatefulWidget {
  final int value;
  final int max;
  final double height;
  final Color fill;
  final Color trough;

  const LagBar({
    super.key,
    required this.value,
    required this.max,
    this.height = 8,
    this.fill = CombatPalette.blood,
    this.trough = CombatPalette.bloodTrough,
  });

  @override
  State<LagBar> createState() => _LagBarState();
}

class _LagBarState extends State<LagBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  double _from = 0;

  double get _fraction => widget.max <= 0 ? 0 : (widget.value / widget.max).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _from = _fraction;
    _c.value = 1;
  }

  @override
  void didUpdateWidget(covariant LagBar old) {
    super.didUpdateWidget(old);
    final oldF = old.max <= 0 ? 0.0 : (old.value / old.max).clamp(0.0, 1.0);
    if (_fraction < oldF) {
      // Start the trail from wherever it currently is, then drain after a short hold.
      _from = _currentLag(oldF);
      _c.forward(from: 0);
    } else {
      _from = _fraction;
      _c.value = 1;
    }
  }

  double _currentLag(double fallback) {
    if (_c.isAnimating) {
      final t = Curves.easeIn.transform(((_c.value - 0.2) / 0.8).clamp(0.0, 1.0));
      return _from + (_fraction - _from) * t;
    }
    return fallback;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        final t = reduce ? 1.0 : Curves.easeIn.transform(((_c.value - 0.2) / 0.8).clamp(0.0, 1.0));
        final lag = _from + (_fraction - _from) * t;
        return SizedBox(
          height: widget.height,
          child: CustomPaint(painter: _BarPainter(_fraction, math.max(lag, _fraction), widget.fill, widget.trough)),
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  final double fill;
  final double lag;
  final Color fillColor;
  final Color trough;
  _BarPainter(this.fill, this.lag, this.fillColor, this.trough);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..color = trough);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * lag, size.height),
        Paint()..color = CombatPalette.parchment.withValues(alpha: 0.55));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * fill, size.height), Paint()..color = fillColor);
    final tick = Paint()..color = CombatPalette.ground.withValues(alpha: 0.55);
    for (var i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawRect(Rect.fromLTWH(x - 0.5, 0, 1, size.height), tick);
    }
    // carved top edge
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1), Paint()..color = Colors.black.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.fill != fill || old.lag != lag || old.fillColor != fillColor || old.trough != trough;
}

// ─── AP pips ─────────────────────────────────────────────────────────────────

/// Action points as diamonds. Pips a held skill would spend pulse as a preview.
class ApPips extends StatefulWidget {
  final int current;
  final int max;
  final int preview;
  const ApPips({super.key, required this.current, this.max = 3, this.preview = 0});

  @override
  State<ApPips> createState() => _ApPipsState();
}

class _ApPipsState extends State<ApPips> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant ApPips oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  /// Pulse only while a cost is being previewed, so the screen can go idle.
  void _syncPulse() {
    if (widget.preview > 0) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating || _pulse.value != 0) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.current} of ${widget.max} action points',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.max, (i) {
              final full = i < widget.current;
              final previewed = full && i >= widget.current - widget.preview;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Opacity(
                    opacity: previewed ? 0.35 + 0.65 * (1 - _pulse.value) : 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: full && !previewed ? CombatPalette.brass : Colors.transparent,
                        border: Border.all(color: CombatPalette.brass),
                        boxShadow: full && !previewed
                            ? [BoxShadow(color: CombatPalette.brass.withValues(alpha: 0.45), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── Intent badge ────────────────────────────────────────────────────────────

class IntentBadge extends StatelessWidget {
  final EnemyIntent intent;
  final String? targetName;
  const IntentBadge(this.intent, {super.key, this.targetName});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String text, String tip) = switch (intent.kind) {
      IntentKind.attack => (
          Icons.colorize,
          '${intent.estimatedDamage}',
          'Will attack ${targetName ?? 'you'} for about ${intent.estimatedDamage}'
        ),
      IntentKind.advance => (Icons.south, 'ADV', 'Will advance to the front line'),
      IntentKind.charge => (Icons.south, 'CHG', 'Will charge to the front line'),
      IntentKind.retreat => (Icons.north, 'RET', 'Will fall back to the back line'),
      IntentKind.hold => (Icons.pause, 'WAIT', 'Can\'t reach you; will wait'),
    };
    final attack = intent.kind == IntentKind.attack;
    return Tooltip(
      message: tip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        color: attack ? CombatPalette.rust : CombatPalette.raised,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: attack ? CombatPalette.bone : CombatPalette.ash),
            const SizedBox(width: 3),
            Text(text,
                style: VitruvianTypography.monospaceData(
                    fontSize: 10, fontWeight: FontWeight.w700, color: attack ? CombatPalette.bone : CombatPalette.ash)),
            if (attack && targetName != null) ...[
              const SizedBox(width: 3),
              Text('→${targetName!.split(' ').first.toUpperCase()}',
                  style: VitruvianTypography.monospaceData(fontSize: 9, color: CombatPalette.bone)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Combatant card ──────────────────────────────────────────────────────────

/// Any fighter on the battlefield. Hit effects (lean, flash, knockback) are driven
/// by the screen through [offset] and [flash].
class CombatantCard extends StatelessWidget {
  final String name;
  final String image;
  final int hp;
  final int maxHp;
  final List<StatusMark> statuses;
  final Widget? intent;
  final bool selected;
  final bool ally;
  final bool isPlayer;
  final bool outOfReach;
  final bool acting;
  final bool dropHighlight;
  final double scale;
  final Offset offset;
  final double flash;
  final Widget? popup;
  final VoidCallback? onTap;

  static const double width = 96;
  static const double artHeight = 88;

  const CombatantCard({
    super.key,
    required this.name,
    required this.image,
    required this.hp,
    required this.maxHp,
    this.statuses = const [],
    this.intent,
    this.selected = false,
    this.ally = false,
    this.isPlayer = false,
    this.outOfReach = false,
    this.acting = false,
    this.dropHighlight = false,
    this.scale = 1,
    this.offset = Offset.zero,
    this.flash = 0,
    this.popup,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected || dropHighlight
        ? CombatPalette.brass
        : isPlayer
            ? CombatPalette.sepia
            : ally
                ? CombatPalette.lapis
                : CombatPalette.hairlineStrong;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      width: width,
      transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
      decoration: BoxDecoration(
        color: CombatPalette.surface,
        border: Border.all(color: border, width: selected || acting ? 1.6 : 1),
        boxShadow: selected || dropHighlight
            ? [BoxShadow(color: CombatPalette.brass.withValues(alpha: 0.4), blurRadius: 10)]
            : acting
                ? [BoxShadow(color: border.withValues(alpha: 0.35), blurRadius: 8)]
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: artHeight,
            width: width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: artHeight * 1.7,
                    child: Image.asset(
                      image,
                      width: width,
                      height: artHeight * 1.7,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.7),
                      color: outOfReach ? Colors.black.withValues(alpha: 0.5) : null,
                      colorBlendMode: outOfReach ? BlendMode.darken : null,
                      errorBuilder: (_, _, _) => const ColoredBox(color: CombatPalette.sunk),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.3),
                      radius: 1.0,
                      colors: [Colors.transparent, Color(0xB3050505)],
                      stops: [0.6, 1.0],
                    ),
                  ),
                ),
                if (flash > 0)
                  IgnorePointer(child: ColoredBox(color: CombatPalette.wound.withValues(alpha: 0.6 * flash))),
                if (outOfReach)
                  Align(
                    alignment: const Alignment(0, 0.8),
                    child: Text('OUT OF REACH',
                        style: VitruvianTypography.monospaceData(fontSize: 9, color: CombatPalette.parchment)),
                  ),
                Positioned(
                  left: 4,
                  top: 4,
                  child: Column(
                    children: [
                      for (final s in statuses) ...[StatusSigil(s), const SizedBox(height: 6)],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 3, 5, 0),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VitruvianTypography.serifTitle(fontSize: 12, color: CombatPalette.parchment),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 2, 5, 5),
            child: Column(
              children: [
                LagBar(
                  value: hp,
                  max: maxHp,
                  height: 4,
                  fill: ally ? CombatPalette.lapis : CombatPalette.blood,
                  trough: ally ? const Color(0xFF0A1A22) : CombatPalette.bloodTrough,
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('$hp/$maxHp',
                      style: VitruvianTypography.monospaceData(fontSize: 10, color: CombatPalette.ash)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Transform.translate(
      offset: offset,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              if (intent != null) Positioned(right: -1, top: -1, child: intent!),
              if (selected)
                Positioned(
                  left: width / 2 - 4,
                  bottom: -10,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(width: 8, height: 8, color: CombatPalette.brass),
                  ),
                ),
              if (popup != null) Positioned(left: -20, right: -20, top: -26, child: Center(child: popup!)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Turn order ribbon ───────────────────────────────────────────────────────

class OrderSlot {
  final String id;
  final String image;
  final bool enemy;
  const OrderSlot(this.id, this.image, {this.enemy = false});
}

class OrderRibbon extends StatelessWidget {
  final List<OrderSlot> slots;
  final String? currentId;
  const OrderRibbon({super.key, required this.slots, this.currentId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in slots)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: s.id == currentId ? 28 : 22,
              height: s.id == currentId ? 28 : 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: s.id == currentId
                      ? CombatPalette.brass
                      : s.enemy
                          ? CombatPalette.rust
                          : CombatPalette.hairlineStrong,
                ),
                color: CombatPalette.sunk,
              ),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: 48,
                  child: Image.asset(s.image, width: 28, height: 48, fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.8),
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
