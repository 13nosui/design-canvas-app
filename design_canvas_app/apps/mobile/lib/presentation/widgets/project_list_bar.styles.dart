import 'package:flutter/material.dart';

class ProjectListBarStyles {
  ProjectListBarStyles._();

  static const double barHeight = 48.0;
  static const Color barBackground = Color(0xFF1E293B);
  static const Color cardBackground = Color(0xFF334155);
  static const Color cardBackgroundSelected = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFFE2E8F0);
  static const Color textColorMuted = Color(0xFF94A3B8);
  static const double cardRadius = 8.0;
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets barPadding =
      EdgeInsets.symmetric(horizontal: 12);
  static const double cardSpacing = 8.0;
  static const double iconSize = 14.0;
  static const TextStyle nameStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  static const TextStyle allProjectsStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textColorMuted,
  );
}
