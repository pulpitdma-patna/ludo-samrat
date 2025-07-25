import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:frontend/theme.dart';

class AuthFooter extends StatelessWidget {
  final String? prefixText;
  final String actionText;
  final VoidCallback onTap;
  final bool isBack;

  const AuthFooter({
    Key? key,
    this.prefixText,
    required this.actionText,
    required this.onTap,
    this.isBack = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isBack) {
      return TextButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 18.h,
            ),
            SizedBox(width: 5.w),
            Text(
              actionText,
              style: AppTextStyles.poppinsRegular.copyWith(
                color: Colors.white,
                fontSize: AppTextStyles.body.fontSize!.sp,
              ),
            ),
          ],
        ),
      );
    } else if (prefixText != null) {
      return RichText(
        text: TextSpan(
          text: prefixText!,
          style: AppTextStyles.poppinsRegular.copyWith(
            color: AppColors.white.withOpacity(0.5),
            fontSize: AppTextStyles.body.fontSize!.sp,
          ),
          children: [
            TextSpan(
              text: actionText,
              style: AppTextStyles.poppinsMedium.copyWith(
                color: AppColors.gradientYellowStart,
                fontSize: AppTextStyles.body.fontSize!.sp,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      );
    } else {
      return TextButton(
        onPressed: onTap,
        child: Text(
          actionText,
          style: AppTextStyles.poppinsRegular.copyWith(
            color: Colors.white,
            fontSize: AppTextStyles.body.fontSize!.sp,
          ),
        ),
      );
    }
  }
}
