import 'package:flutter/material.dart';

enum WatermarkPosition {
  bottomCenter,
  bottomRight,
  bottomLeft,
}

class WatermarkConfig {
  final String text;
  final double fontSize;
  final double opacity; // 0.1 to 1.0 (e.g., 0.7 for subtle/light)
  final WatermarkPosition position;
  final int bottomMargin; // pixels from bottom edge
  final bool showBackgroundBox;
  final double boxOpacity;
  final Color textColor;
  final Color boxColor;

  const WatermarkConfig({
    required this.text,
    this.fontSize = 28.0,
    this.opacity = 0.75,
    this.position = WatermarkPosition.bottomCenter,
    this.bottomMargin = 35,
    this.showBackgroundBox = true,
    this.boxOpacity = 0.35,
    this.textColor = Colors.white,
    this.boxColor = Colors.black,
  });

  WatermarkConfig copyWith({
    String? text,
    double? fontSize,
    double? opacity,
    WatermarkPosition? position,
    int? bottomMargin,
    bool? showBackgroundBox,
    double? boxOpacity,
    Color? textColor,
    Color? boxColor,
  }) {
    return WatermarkConfig(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      position: position ?? this.position,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      showBackgroundBox: showBackgroundBox ?? this.showBackgroundBox,
      boxOpacity: boxOpacity ?? this.boxOpacity,
      textColor: textColor ?? this.textColor,
      boxColor: boxColor ?? this.boxColor,
    );
  }

  /// Generates the FFmpeg video filter (-vf) string for drawtext
  String buildFfmpegFilter({String? customFontPath}) {
    // Escape special characters for FFmpeg drawtext
    final escapedText = text
        .replaceAll(r'\', r'\\')
        .replaceAll(':', r'\:')
        .replaceAll("'", r"\'")
        .replaceAll('%', r'\%');

    // Calculate X coordinate
    String xExpr;
    switch (position) {
      case WatermarkPosition.bottomLeft:
        xExpr = '40';
        break;
      case WatermarkPosition.bottomRight:
        xExpr = 'w-text_w-40';
        break;
      case WatermarkPosition.bottomCenter:
      default:
        xExpr = '(w-text_w)/2';
        break;
    }

    // Calculate Y coordinate (Always at bottom with margin)
    final yExpr = 'h-text_h-$bottomMargin';

    // Alpha/opacity formatting
    final alphaStr = opacity.toStringAsFixed(2);
    final boxAlphaStr = boxOpacity.toStringAsFixed(2);

    final buffer = StringBuffer('drawtext=');
    buffer.write("text='$escapedText'");
    buffer.write(':fontsize=$fontSize');
    buffer.write(':fontcolor=white@$alphaStr');
    buffer.write(':x=$xExpr');
    buffer.write(':y=$yExpr');

    if (customFontPath != null && customFontPath.isNotEmpty) {
      final safeFontPath = customFontPath.replaceAll(r'\', '/').replaceAll(':', r'\:');
      buffer.write(":fontfile='$safeFontPath'");
    }

    if (showBackgroundBox) {
      buffer.write(':box=1:boxcolor=black@$boxAlphaStr:boxborderw=8');
    } else {
      // Subtle text shadow for readability if no box
      buffer.write(':shadowcolor=black@0.5:shadowx=2:shadowy=2');
    }

    return buffer.toString();
  }
}
