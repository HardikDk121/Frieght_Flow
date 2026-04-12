import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary      = Color(0xFF1B4F8A); // deep navy blue
  static const Color primaryLight = Color(0xFF2D6BB5);
  static const Color accent       = Color(0xFFE8A020); // amber gold
  static const Color accentDark   = Color(0xFFC47E08);

  // Semantic
  static const Color success      = Color(0xFF1E7E52);
  static const Color successLight = Color(0xFFE6F4ED);
  static const Color warning      = Color(0xFFA86000);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color danger       = Color(0xFFC0392B);
  static const Color dangerLight  = Color(0xFFFDEDEC);
  static const Color info         = Color(0xFF1565C0);
  static const Color infoLight    = Color(0xFFE3F0FF);

  // Surface
  static const Color surface      = Color(0xFFF4F6FA);  // cool light bg
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color divider      = Color(0xFFE8EAF0);

  // Text
  static const Color textPrimary  = Color(0xFF0D1B2A);
  static const Color textSecondary= Color(0xFF5A6580);
  static const Color textMuted    = Color(0xFF9BA4B8);
  static const Color textOnDark   = Color(0xFFFFFFFF);

  // Dashboard card gradient pairs [start, end]
  static const List<Color> gradBlue    = [Color(0xFF1B4F8A), Color(0xFF2D6BB5)];
  static const List<Color> gradAmber   = [Color(0xFFB86A00), Color(0xFFE8A020)];
  static const List<Color> gradGreen   = [Color(0xFF1A6640), Color(0xFF2E9E65)];
  static const List<Color> gradSlate   = [Color(0xFF3D4E6B), Color(0xFF5A6E90)];
}
