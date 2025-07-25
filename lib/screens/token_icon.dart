import "package:flutter/material.dart";
enum TokenIcon { circle, square, triangle, star }

extension TokenIconData on TokenIcon {
  IconData get icon {
    switch (this) {
      case TokenIcon.square:
        return Icons.square;
      case TokenIcon.triangle:
        return Icons.change_history; // triangle icon
      case TokenIcon.star:
        return Icons.star;
      case TokenIcon.circle:
      default:
        return Icons.circle;
    }
  }
}
