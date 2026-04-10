import 'package:flutter/material.dart';

class CanvasToolbarStyles {
  CanvasToolbarStyles._();

  static const double height = 48.0;
  static const Color borderColor = Color(0xFFE2E8F0);
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 12);

  static const TextStyle titleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle zoomStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF64748B),
  );
}
