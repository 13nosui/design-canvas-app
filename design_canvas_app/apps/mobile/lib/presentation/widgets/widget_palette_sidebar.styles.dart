import 'package:flutter/material.dart';

class WidgetPaletteSidebarStyles {
  WidgetPaletteSidebarStyles._();

  static const double sidebarWidth = 240.0;
  static const Color background = Color(0xFFF8FAFC);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color searchBackground = Color(0xFFF1F5F9);
  static const Color categoryHeaderColor = Color(0xFF64748B);
  static const Color itemColor = Color(0xFF1E293B);
  static const Color itemHoverColor = Color(0xFFEFF6FF);
  static const Color dragFeedbackColor = Color(0xFF3B82F6);

  static const EdgeInsets sidebarPadding = EdgeInsets.all(0);
  static const EdgeInsets searchPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets itemPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  static const TextStyle searchHintStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF94A3B8),
  );
  static const TextStyle categoryStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: categoryHeaderColor,
  );
  static const TextStyle itemStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: itemColor,
  );
  static const TextStyle dragFeedbackStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
