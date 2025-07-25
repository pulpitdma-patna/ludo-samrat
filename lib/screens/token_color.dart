import 'package:flutter/material.dart';

enum TokenColor { red, blue, green, yellow }

extension TokenColorData on TokenColor {
  Color get color {
    switch (this) {
      case TokenColor.blue:
        return Colors.blue;
      case TokenColor.green:
        return Colors.green;
      case TokenColor.yellow:
        return Colors.yellow;
      case TokenColor.red:
      default:
        return Colors.red;
    }
  }
}
