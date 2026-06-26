import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Draws a subtle 1px dotted sepia hairline connecting UI elements
class DottedHairline extends StatelessWidget {
  const DottedHairline({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CustomPaint(
          painter: _DottedLinePainter(),
          child: const SizedBox(height: 1),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VitruvianColors.sepiaUmber.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    double dashWidth = 2.0;
    double dashSpace = 4.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Razor-sharp 0px corner radius diegetic toggle switch
class EtchedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const EtchedSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: VitruvianColors.voidBlack,
          borderRadius: BorderRadius.zero, // Razor-sharp 0px corner radiuses
          border: Border.all(color: VitruvianColors.sepiaUmber, width: 1.0),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 18,
                decoration: BoxDecoration(
                  color: value ? VitruvianColors.agedBone : const Color(0xFF2A2520),
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom rectangular slider thumb shape (0px radius vellum block)
class RectangularSliderThumbShape extends SliderComponentShape {
  final double width;
  final double height;

  const RectangularSliderThumbShape({this.width = 8.0, this.height = 20.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? VitruvianColors.agedBone
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawRect(rect, paint);

    // Subtle hairline border on thumb
    final borderPaint = Paint()
      ..color = VitruvianColors.sepiaUmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);
  }
}
