import 'package:flutter/material.dart';
import 'theme.dart';

const double authLogoWidth = 164;

/// Common gradient definitions used across the app.
class AppGradients {
  static LinearGradient get blueVertical => LinearGradient(
        colors: [
          AppColors.primaryGradient,
          AppColors.secondPrimaryGradient,
          AppColors.primaryGradient,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static const LinearGradient gold = LinearGradient(
    colors: [
      Color(0xffFFD700),
      Color(0xffFFA500),
      Color(0xffFF8C00),
    ],
  );

  static const LinearGradient yellow = LinearGradient(
    colors: [
      Color(0xffFACC15),
      Color(0xffCA8A04),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient yellowOrange = LinearGradient(
    colors: [
      Color(0xFFFBBF24),
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient orange = LinearGradient(
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
      Color(0xFFB45309),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient blueHorizontal = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3730A3)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient walletCardGradient = LinearGradient(
    colors: [Color(0xFF1438A6), AppColors.deepBlue],
    begin: Alignment.centerLeft,
    end: Alignment.bottomCenter,
  );
}

/// Common spacing values to avoid magic numbers.
class AppSpacing {
  /// Default horizontal padding used for pages.
  static const double horizontal = 16.0;

  /// Default vertical spacing between major sections.
  static const double section = 20.0;
}
