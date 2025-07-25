import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

/// Reusable row widget for lists showing an icon, title, subtitle and amount.
class TransactionRow extends StatelessWidget {
  /// Leading widget, typically an icon wrapped with decoration.
  final Widget leading;

  /// Main title of the row.
  final String title;

  /// Subtitle text below the title.
  final String subtitle;

  /// Trailing amount or status text.
  final String amount;

  /// Color of the amount text.
  final Color amountColor;

  /// Color of the subtitle text.
  final Color subtitleColor;

  /// Color of the title text.
  final Color titleColor;

  /// Background color of the row container.
  final Color backgroundColor;

  /// Border radius of the container.
  final BorderRadiusGeometry borderRadius;

  /// Optional border of the container.
  final BoxBorder? border;

  /// Padding inside the row container.
  final EdgeInsetsGeometry padding;

  const TransactionRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    this.subtitleColor = const Color(0xffD1D5DB),
    this.titleColor = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 14.sp,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTextStyles.poppinsRegular.copyWith(
                    fontSize: 12.sp,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 14.sp,
                    color: amountColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
