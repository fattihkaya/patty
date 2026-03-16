import 'package:flutter/material.dart';
import '../../core/constants.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.gradient,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return (gradient ?? AppConstants.primaryGradient)
            .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: style ?? AppConstants.headlineMedium.copyWith(color: Colors.white),
        textAlign: textAlign,
      ),
    );
  }
}
