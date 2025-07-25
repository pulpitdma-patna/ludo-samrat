import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:frontend/app_images.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/constants.dart';

class AuthHeader extends StatelessWidget {
  final String? headline;
  final String? subtitle;
  final double logoWidth;

  const AuthHeader({
    Key? key,
    this.headline,
    this.subtitle,
    this.logoWidth = authLogoWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          AppImages.logo,
          width: logoWidth.w,
          fit: BoxFit.cover,
        ),
        if (headline != null) SizedBox(height: 8.h),
        if (headline != null)
          Text(
            headline!,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppinsBold.copyWith(
              color: AppColors.white,
              fontSize: AppTextStyles.headingLarge.fontSize!.sp,
            ),
          ),
        if (subtitle != null) SizedBox(height: 8.h),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppinsRegular.copyWith(
              color: AppColors.white.withOpacity(0.7),
              fontSize: AppTextStyles.body.fontSize!.sp,
            ),
          ),
      ],
    );
  }
}
