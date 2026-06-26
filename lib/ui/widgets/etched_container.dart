import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class EtchedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color borderColor;
  final Color? backgroundColor;
  final double borderWidth;
  final double? width;
  final double? height;

  const EtchedContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12.0),
    this.margin,
    this.borderColor = VitruvianColors.etchedHairline,
    this.backgroundColor,
    this.borderWidth = 1.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? VitruvianColors.voidBlack,
        borderRadius: BorderRadius.zero, // Razor-sharp 0px corner radiuses
        border: Border.all(
          color: borderColor,
          width: borderWidth, // 1px etched hairlines
        ),
      ),
      child: child,
    );
  }
}
