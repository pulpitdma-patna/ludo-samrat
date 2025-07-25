import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';
import '../utils/svg_icon.dart';

/// Generic widget to display a statistics value with optional icon.
class StatBox extends StatelessWidget {
  /// Numeric or textual value to show prominently.
  final String value;

  /// Label describing the value.
  final String label;

  /// Background color of the box.
  final Color backgroundColor;

  /// Text color for the value.
  final Color valueColor;

  /// Text color for the label.
  final Color labelColor;

  /// Optional border of the container.
  final BoxBorder? border;

  /// Corner radius of the container.
  final BorderRadiusGeometry borderRadius;

  /// Padding inside the box.
  final EdgeInsetsGeometry padding;

  /// Optional icon path to display next to the label.
  final String? iconPath;

  /// Color of the optional icon.
  final Color? iconColor;

  /// Whether value and label should be centered.
  final bool centerContent;

  /// Width of the box when [centerContent] is `true`.
  final double? width;

  /// Height of the box when [centerContent] is `true`.
  final double? height;

  const StatBox({
    super.key,
    required this.value,
    required this.label,
    required this.backgroundColor,
    this.valueColor = Colors.white,
    this.labelColor = Colors.white,
    this.border,
    this.borderRadius = BorderRadius.zero,
    this.padding = const EdgeInsets.all(8),
    this.iconPath,
    this.iconColor,
    this.centerContent = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      style: AppTextStyles.poppinsBold.copyWith(
        fontSize: centerContent ? 18.sp : 24.sp,
        color: valueColor,
      ),
    );

    final labelWidget = Text(
      label,
      style: AppTextStyles.poppinsRegular.copyWith(
        fontSize: 12.sp,
        color: labelColor,
      ),
    );

    return Container(
      width: centerContent ? width : null,
      height: centerContent ? height : null,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
        borderRadius: borderRadius,
      ),
      child: iconPath != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    svgIcon(
                      name: iconPath!,
                      width: 20.w,
                      height: 20.h,
                      color: iconColor,
                      semanticsLabel: label,
                    ),
                    labelWidget,
                  ],
                ),
                SizedBox(height: 8.h),
                valueWidget,
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                valueWidget,
                SizedBox(height: 4.h),
                labelWidget,
              ],
            ),
    );
  }
}
