import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF162032);
  static const Color surfaceElevated = Color(0xFF1E2D3D);
  static const Color cardBorder = Color(0xFF2A3F55);

  // Accent / Brand
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF0099AA);
  static const Color secondary = Color(0xFF26D0CE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E2D3D), Color(0xFF162032)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient energyGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF7B1FA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color danger = Color(0xFFFF1744);
  static const Color info = Color(0xFF29B6F6);

  // Sensor specific
  static const Color tempColor = Color(0xFFFF7043);
  static const Color humidColor = Color(0xFF29B6F6);
  static const Color co2Color = Color(0xFF66BB6A);
  static const Color smokeColor = Color(0xFFBDBDBD);
  static const Color flameColor = Color(0xFFFF3D00);
  static const Color energyColor = Color(0xFFFFD600);

  // Text
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF8BACC8);
  static const Color textMuted = Color(0xFF4A6278);

  // Role colors
  static const Color adminColor = Color(0xFFAB47BC);
  static const Color teacherColor = Color(0xFF26C6DA);
  static const Color janitorColor = Color(0xFF66BB6A);
}
