import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme.dart';

class CommonButton extends StatelessWidget {
  final double? width;
  final String? text;
  final Gradient? gradient;
  final Color? btnTextColor;
  final Widget? btnChild;
  final VoidCallback? onPressed;
  final bool isBgColor;
  final BoxBorder? btnBorder;

  const CommonButton({
    super.key,
    this.width,
    this.text,
    this.gradient,
    this.btnTextColor,
    this.btnChild,
    this.onPressed,
    this.isBgColor = true,
    this.btnBorder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56.h,
        width: width ?? 342.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isBgColor
              ? gradient ?? _defaultGradient(context)
              : null,
          borderRadius: BorderRadius.circular(12.r),
          border: btnBorder
        ),
        child: btnChild ?? Text(
          text ?? '',
          style: AppTextStyles.poppinsSemiBold.copyWith(
            color: btnTextColor ?? AppColors.brandPrimary,
            fontSize: AppTextStyles.body.fontSize,
          ),
        ),
      ),
    );
  }

  LinearGradient _defaultGradient(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.primary;
    return LinearGradient(
      colors: [baseColor, baseColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}
