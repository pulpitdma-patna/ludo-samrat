import 'package:flutter/material.dart';
import '../theme.dart'; // Make sure this has AppColors defined

class CommonLoader extends StatelessWidget {
  final String? message;
  final Color loaderColor;

  const CommonLoader({
    super.key,
    this.message,
    this.loaderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: loaderColor),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
