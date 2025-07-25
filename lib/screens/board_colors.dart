import 'package:flutter/material.dart';
import '../theme.dart';

enum BoardPalette { classic, samrat }

extension BoardPaletteData on BoardPalette {
  BoardColors get colors {
    switch (this) {
      case BoardPalette.samrat:
        return BoardColors.samrat;
      case BoardPalette.classic:
      default:
        return BoardColors.classic;
    }
  }
}

class BoardColors {
  final Color red;
  final Color green;
  final Color yellow;
  final Color blue;

  const BoardColors({
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
  });

  static const classic = BoardColors(
    red: Colors.red,
    green: Colors.green,
    yellow: Colors.yellow,
    blue: Colors.blue,
  );

  static const samrat = BoardColors(
    red: AppColors.deepBlue,
    green: AppColors.gold,
    yellow: AppColors.gold,
    blue: AppColors.deepBlue,
  );
}
