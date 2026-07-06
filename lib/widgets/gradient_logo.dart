import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class VedoGradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;

  const VedoGradientText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.gradientTextColors,
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: Colors.white,
        ),
      ),
    );
  }
}
