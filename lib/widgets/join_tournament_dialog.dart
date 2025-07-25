import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common_widget/common_button.dart';
import '../constants.dart';
import '../theme.dart';

/// Displays a styled confirmation dialog before joining a tournament.
Future<bool?> showJoinTournamentDialog(BuildContext context, {required double fee}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _JoinTournamentDialog(fee: fee),
  );
}

class _JoinTournamentDialog extends StatelessWidget {
  final double fee;
  const _JoinTournamentDialog({required this.fee});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: AppGradients.blueVertical,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.brandYellowColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Join Tournament?',
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
                      'Join',
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
    );
  }
}

