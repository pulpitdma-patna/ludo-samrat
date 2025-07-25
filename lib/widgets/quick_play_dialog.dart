import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common_widget/common_button.dart';
import '../constants.dart';
import '../theme.dart';

/// Displays a styled confirmation bottom sheet before starting a quick play match.
Future<bool?> showQuickPlayDialog(BuildContext context, {required double fee}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _QuickPlayDialog(fee: fee),
  );
}

class _QuickPlayDialog extends StatelessWidget {
  final double fee;
  const _QuickPlayDialog({required this.fee});

  @override
  Widget build(BuildContext context) {
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
            gradient: AppGradients.blueVertical,
            borderRadius: BorderRadius.circular(20.r),
            border:
                Border.all(color: AppColors.brandYellowColor.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Start Quick Play?',
                style: AppTextStyles.poppinsSemiBold.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Entry fee is \u20b9${fee.toStringAsFixed(0)}',
                style: AppTextStyles.poppinsRegular.copyWith(
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      onPressed: () => Navigator.pop(context, false),
                      btnChild: Text(
                        'Cancel',
                        style: AppTextStyles.poppinsSemiBold.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CommonButton(
                      onPressed: () => Navigator.pop(context, true),
                      btnChild: Text(
                        'Play',
                        style: AppTextStyles.poppinsSemiBold.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

