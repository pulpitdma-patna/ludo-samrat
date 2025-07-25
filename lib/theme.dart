import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      primaryColor: AppColors.brandPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          foregroundColor: Colors.white,
        ),
      ),
      cardColor: Colors.white,
      fontFamily: AppFonts.poppins,
      textTheme:
          GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.brandPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          foregroundColor: Colors.white,
        ),
      ),
      cardColor: const Color(0xFF1f2937),
      fontFamily: AppFonts.poppins,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  /// Backwards compatibility for code that still references [theme].
  static ThemeData get theme => light;
}


class AppColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Colors.black;
  static const Color brandBlue = Color(0xff1d4ed8); // darker for better contrast
  static const Color brandGreen = Color(0xff059669); // increased contrast
  static const Color brandPurple = Color(0xff6d28d9); // darker shade
  static const Color brandYellow = Color(0xffd97706);
  static const Color brandRed = Color(0xffb91c1c); // accessible red
  static const Color brandPink = Color(0xffc2185b); // accessible pink
  static const Color brandIndigo = Color(0xff3f51b5); // improved contrast
  static const Color brandTeal = Color(0xff0d9488); // darker teal
  static const Color brandGray = Color(0xff6b7280);
  static const Color brandPrimary = Color(0xff1e40af);
  static const Color brandSecondary = Color(0xff475569);
  static const Color brandAccent = Color(0xff9c27b0); // darker accent for contrast
  static const Color primaryGradient = Color(0xFF1A237E);
  static const Color secondPrimaryGradient = Color(0xFF283593);
  static const Color gradientYellowStart = Color(0xFFFBBF24);
  static const Color gradientYellowEnd = Color(0xFFFCD34D);
  static const Color pinPutBorderColor = Color(0xFFFBBF24);
  static const Color brandYellowColor = Color(0xFFFACC15);
  static const Color activeColor = Color(0xff1E3A8A);
  static const Color wonColor = Color(0xff14532D);
  static const Color earningColor = Color(0xff581C87);
  static const Color smallTextColor = Color(0xffBFDBFE);
  static const Color activeFilterColor = Color(0xffEAB308);
  static const Color unActiveFilterColor = Color(0xff374151);
  static const Color deepBlue = Color(0xFF0A1E63);
  static const Color gold = Color(0xffE5C158);
}

class AppFonts {
  static const String inter = 'Inter';
  static const String poppins = 'Poppins';
}

class AppTextStyles {
  static const TextStyle poppins = TextStyle();

  static const TextStyle poppinsLabel = TextStyle(
    color: Color(0xFFADAEBC),
  );

  static const TextStyle poppinsBold = TextStyle(
    fontWeight: FontWeight.w700,
  );
  static const TextStyle poppinsSemiBold = TextStyle(
    fontWeight: FontWeight.w600,
  );
  static const TextStyle poppinsMedium = TextStyle(
    fontWeight: FontWeight.w500,
  );
  static const TextStyle poppinsRegular = TextStyle(
    fontWeight: FontWeight.w400,
  );

  // Standardized text sizes
  static const TextStyle headingLarge = TextStyle(fontSize: 24);
  static const TextStyle headingSmall = TextStyle(fontSize: 18);
  static const TextStyle body = TextStyle(fontSize: 14);
  static const TextStyle caption = TextStyle(fontSize: 12);
}

