import 'package:flutter/material.dart';

class GoogleFontsConfig {
  bool allowRuntimeFetching = false;
}

class GoogleFonts {
  static final config = GoogleFontsConfig();

  static TextStyle outfit({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return TextStyle(
      fontFamily: 'Outfit',
      color: color,
      backgroundColor: backgroundColor ?? textStyle?.backgroundColor,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      fontStyle: fontStyle ?? textStyle?.fontStyle,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
      wordSpacing: wordSpacing ?? textStyle?.wordSpacing,
      textBaseline: textBaseline ?? textStyle?.textBaseline,
      height: height ?? textStyle?.height,
      locale: locale ?? textStyle?.locale,
      foreground: foreground ?? textStyle?.foreground,
      background: background ?? textStyle?.background,
      shadows: shadows ?? textStyle?.shadows,
      decoration: decoration ?? textStyle?.decoration,
      decorationColor: decorationColor ?? textStyle?.decorationColor,
      decorationStyle: decorationStyle ?? textStyle?.decorationStyle,
      decorationThickness: decorationThickness ?? textStyle?.decorationThickness,
    );
  }

  static TextStyle robotoMono({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return TextStyle(
      fontFamily: 'monospace',
      color: color,
      backgroundColor: backgroundColor ?? textStyle?.backgroundColor,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      fontStyle: fontStyle ?? textStyle?.fontStyle,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
      wordSpacing: wordSpacing ?? textStyle?.wordSpacing,
      textBaseline: textBaseline ?? textStyle?.textBaseline,
      height: height ?? textStyle?.height,
      locale: locale ?? textStyle?.locale,
      foreground: foreground ?? textStyle?.foreground,
      background: background ?? textStyle?.background,
      shadows: shadows ?? textStyle?.shadows,
      decoration: decoration ?? textStyle?.decoration,
      decorationColor: decorationColor ?? textStyle?.decorationColor,
      decorationStyle: decorationStyle ?? textStyle?.decorationStyle,
      decorationThickness: decorationThickness ?? textStyle?.decorationThickness,
    );
  }

  static TextTheme outfitTextTheme([TextTheme? baseTheme]) {
    baseTheme ??= const TextTheme();
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(fontFamily: 'Outfit'),
      displayMedium: baseTheme.displayMedium?.copyWith(fontFamily: 'Outfit'),
      displaySmall: baseTheme.displaySmall?.copyWith(fontFamily: 'Outfit'),
      headlineLarge: baseTheme.headlineLarge?.copyWith(fontFamily: 'Outfit'),
      headlineMedium: baseTheme.headlineMedium?.copyWith(fontFamily: 'Outfit'),
      headlineSmall: baseTheme.headlineSmall?.copyWith(fontFamily: 'Outfit'),
      titleLarge: baseTheme.titleLarge?.copyWith(fontFamily: 'Outfit'),
      titleMedium: baseTheme.titleMedium?.copyWith(fontFamily: 'Outfit'),
      titleSmall: baseTheme.titleSmall?.copyWith(fontFamily: 'Outfit'),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontFamily: 'Outfit'),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontFamily: 'Outfit'),
      bodySmall: baseTheme.bodySmall?.copyWith(fontFamily: 'Outfit'),
      labelLarge: baseTheme.labelLarge?.copyWith(fontFamily: 'Outfit'),
      labelMedium: baseTheme.labelMedium?.copyWith(fontFamily: 'Outfit'),
      labelSmall: baseTheme.labelSmall?.copyWith(fontFamily: 'Outfit'),
    );
  }
}
