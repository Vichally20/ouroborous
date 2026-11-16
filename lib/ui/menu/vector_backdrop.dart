import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slow-turning backdrop of ellipses, orbit rings and scattered vector marks
/// (constellations, diamonds, ticks) over a deep gradient. Seeded, so every
/// launch draws the same composition; only the rotation moves.
class VectorBackdrop extends StatefulWidget {
  /// Accent tint for the glow behind the centre (the chosen path's colour on onboarding).
  final Color accent;

  /// 0-1: how strong the line work is. Lower it behind dense content.
  final double intensity;

  final Widget? child;

  const VectorBackdrop({super.key, this.accent = const Color(0xFFB0413E), this.intensity = 1, this.child});

  /// Off in widget tests, where a repeating animation never settles.
  static bool animated = true;

  @override
  State<VectorBackdrop> createState() => _VectorBackdropState();
}

class _VectorBackdropState extends State<VectorBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 90));

  @override
  void initState() {
    super.initState();
    if (VectorBackdrop.animated) _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _spin,
            builder: (_, _) => CustomPaint(
              painter: _BackdropPainter(t: _spin.value, accent: widget.accent, intensity: widget.intensity),
            ),
          ),
        ),
        ?widget.child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final double t;
  final Color accent;
  final double intensity;

  _BackdropPainter({required this.t, required this.accent, required this.intensity});

  static const _ink = Color(0xFF07060A);
  static const _deep = Color(0xFF14101C);
  static const _gold = Color(0xFFD9B26F);
  static const _teal = Color(0xFF3E8C88);
  static const _violet = Color(0xFF6C4FA3);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = Offset(size.width / 2, size.height * 0.36);
    final r = math.max(size.width, size.height);
    final a = intensity.clamp(0.0, 1.0);

    // Base: deep violet-black falling to ink.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.1,
          colors: const [_deep, _ink],
        ).createShader(rect),
    );

    // Soft glowing blobs: accent at the centre, teal and violet drifting at the edges.
    void glow(Offset at, double radius, Color color, double alpha) {
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: at, radius: radius)),
      );
    }

    final drift = math.sin(t * math.pi * 2);
    glow(c, r * 0.55, accent, 0.38);
    glow(Offset(size.width * (0.1 + 0.05 * drift), size.height * 0.82), r * 0.45, _teal, 0.22);
    glow(Offset(size.width * (0.95 - 0.05 * drift), size.height * 0.12), r * 0.4, _violet, 0.26);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Concentric tilted ellipses around the centre, each turning at its own pace.
    final ellipses = <(double w, double h, double tilt, double speed, Color color, double alpha, double stroke)>[
      (1.15, 0.42, -0.35, 1, _gold, 0.30, 1.2),
      (0.95, 0.95, 0, 0, _gold, 0.16, 0.8),
      (1.35, 0.55, 0.5, -0.6, accent, 0.30, 1.0),
      (0.7, 0.26, 1.1, 1.6, _teal, 0.32, 1.0),
      (1.6, 0.8, -0.9, 0.4, _violet, 0.22, 0.8),
      (0.55, 0.55, 0, 0, _gold, 0.22, 0.6),
    ];
    final base = size.width * 0.62;
    for (final (w, h, tilt, speed, color, alpha, stroke) in ellipses) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(tilt + speed * t * math.pi * 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: base * w, height: base * h),
        line
          ..color = color.withValues(alpha: alpha * a)
          ..strokeWidth = stroke,
      );
      // A bead riding each moving orbit.
      if (speed != 0) {
        final ang = t * math.pi * 2 * (speed * 2);
        final bead = Offset(math.cos(ang) * base * w / 2, math.sin(ang) * base * h / 2);
        canvas.drawCircle(bead, 2.6, Paint()..color = color.withValues(alpha: 0.9 * a));
      }
      canvas.restore();
    }

    // Dashed outer ring with compass ticks.
    final ringR = base * 0.62;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-t * math.pi * 2 * 0.5);
    for (var i = 0; i < 72; i++) {
      final ang = i * math.pi * 2 / 72;
      final long = i % 9 == 0;
      final inner = ringR - (long ? 10 : 4);
      canvas.drawLine(
        Offset(math.cos(ang) * inner, math.sin(ang) * inner),
        Offset(math.cos(ang) * ringR, math.sin(ang) * ringR),
        line
          ..color = _gold.withValues(alpha: (long ? 0.45 : 0.2) * a)
          ..strokeWidth = long ? 1.2 : 0.8,
      );
    }
    canvas.restore();

    // Scattered vector marks from a fixed seed: constellations, diamonds, crosses, rings.
    final rnd = math.Random(7);
    final stars = List.generate(46, (_) => Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height));
    final twinkle = (t * 6) % 1;
    for (var i = 0; i < stars.length; i++) {
      final p = stars[i];
      final kind = rnd.nextInt(6);
      final s = 2 + rnd.nextDouble() * 4;
      final color = [_gold, _teal, accent, _violet, _gold, Colors.white][kind];
      final alpha = (0.25 + 0.5 * rnd.nextDouble()) * a * (i % 7 == 0 ? (0.5 + 0.5 * math.sin((twinkle + i / 7) * math.pi * 2)) : 1);
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      switch (kind) {
        case 0: // diamond
          final path = Path()
            ..moveTo(p.dx, p.dy - s)
            ..lineTo(p.dx + s * 0.7, p.dy)
            ..lineTo(p.dx, p.dy + s)
            ..lineTo(p.dx - s * 0.7, p.dy)
            ..close();
          canvas.drawPath(path, paint);
        case 1: // cross
          canvas.drawLine(p.translate(-s, 0), p.translate(s, 0), paint);
          canvas.drawLine(p.translate(0, -s), p.translate(0, s), paint);
        case 2: // small ring
          canvas.drawCircle(p, s * 0.8, paint);
        case 3: // tiny triangle
          final path = Path()
            ..moveTo(p.dx, p.dy - s)
            ..lineTo(p.dx + s * 0.87, p.dy + s * 0.5)
            ..lineTo(p.dx - s * 0.87, p.dy + s * 0.5)
            ..close();
          canvas.drawPath(path, paint);
        default: // dot
          canvas.drawCircle(p, 1.2, Paint()..color = color.withValues(alpha: alpha));
      }
    }

    // Constellation lines between near neighbours.
    final link = Paint()
      ..color = _gold.withValues(alpha: 0.10 * a)
      ..strokeWidth = 0.7;
    for (var i = 0; i < stars.length; i++) {
      for (var j = i + 1; j < stars.length; j++) {
        if ((stars[i] - stars[j]).distance < size.shortestSide * 0.18) canvas.drawLine(stars[i], stars[j], link);
      }
    }

    // Vignette so content at the edges stays readable.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.t != t || old.accent != accent || old.intensity != intensity;
}
