import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../common_widget/common_button.dart';
import '../constants.dart';
import '../theme.dart';

/// Shows a bottom sheet prompting the user to complete KYC.
Future<void> showKycModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: AppGradients.walletCardGradient,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xffD4AF37).withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                Text(
                  'KYC Required',
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Please complete your KYC to continue.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppinsRegular.copyWith(
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 24.h),
                CommonButton(
                  width: double.infinity,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/kyc');
                  },
                  btnChild: Text(
                    'Complete KYC',
                    style: AppTextStyles.poppinsMedium.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
