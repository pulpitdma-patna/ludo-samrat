import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

class CommonTextField extends StatelessWidget {
  final double? width;
  final String hintText;
  final String? labelText;
  final TextStyle? labelStyle;
  final Widget? prefixIcon;
  final bool obscureText;
  final IconData? suffixIcon;
  final TextEditingController controller;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final double? noPrefixLeftPadding;
  final bool readOnly;

  const CommonTextField({
    super.key,
    this.width,
    required this.hintText,
    this.labelText,
    this.labelStyle,
    this.prefixIcon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.errorText,
    this.noPrefixLeftPadding,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 58.h,
          width: width ?? 342.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Center(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              onChanged: onChanged,
              readOnly: readOnly,
              style: AppTextStyles.poppinsRegular.copyWith(
                color: Colors.white,
                fontSize: AppTextStyles.body.fontSize!.sp,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                errorStyle: AppTextStyles.poppins.copyWith(height: 0),
                contentPadding: prefixIcon == null
                    ? EdgeInsets.only(left: noPrefixLeftPadding?.w ?? 0)
                    : EdgeInsets.zero,
                border: InputBorder.none,
                labelText: labelText,
                labelStyle: labelStyle,
                hintText: hintText,
                hintStyle: AppTextStyles.poppinsRegular.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: AppTextStyles.body.fontSize!.sp,
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 40.w,
                  minHeight: 20.h,
                ),
                prefixIcon: prefixIcon != null
                    ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: prefixIcon,
                )
                    : null,
                suffixIcon: suffixIcon != null
                    ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Icon(
                      suffixIcon,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                )
                    : null,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 8.w),
            child: Text(
              errorText!,
              style: AppTextStyles.poppinsRegular.copyWith(
                color: Colors.redAccent,
                fontSize: AppTextStyles.caption.fontSize!.sp,
              ),
            ),
          ),
      ],
    );
  }
}


