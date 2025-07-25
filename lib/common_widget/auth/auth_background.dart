import 'package:flutter/material.dart';
import 'package:frontend/theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final String? backgroundImage;

  const AuthBackground({Key? key, required this.child, this.backgroundImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGradient,
                AppColors.secondPrimaryGradient,
                AppColors.secondPrimaryGradient,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        if (backgroundImage != null)
          Positioned.fill(
            child: Image.asset(
              backgroundImage!,
              fit: BoxFit.cover,
            ),
          ),
        child,
      ],
    );
  }
}
