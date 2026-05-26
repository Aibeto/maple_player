import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AppTheme {
  static const String fontFamily = 'MapleMonoNFCN';

  static GlassThemeData glassTheme() {
    return GlassThemeData(
      light: GlassThemeVariant(
        settings: const GlassThemeSettings(thickness: 30, blur: 12),
        quality: GlassQuality.standard,
      ),
      dark: GlassThemeVariant(
        settings: const GlassThemeSettings(thickness: 50, blur: 18),
        quality: GlassQuality.premium,
      ),
    );
  }

  static TextStyle textStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
