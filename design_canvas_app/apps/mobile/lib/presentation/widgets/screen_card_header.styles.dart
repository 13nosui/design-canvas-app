import 'package:flutter/material.dart';

class ScreenCardHeaderStyles {
  ScreenCardHeaderStyles._();

  static const double headerHeight = 32.0;
  static const Color background = Color(0xFF1E293B);
  static const Color textColor = Color(0xFFE2E8F0);
  static const Color iconColor = Color(0xFF94A3B8);
  static const double borderRadius = 8.0;

  static const TextStyle nameStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textColor,
    overflow: TextOverflow.ellipsis,
  );
  static const TextStyle stateStyle = TextStyle(
    fontSize: 10,
    color: textColor,
  );
}
