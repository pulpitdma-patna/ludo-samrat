import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/utils/svg_icon.dart';
import '../theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _buildNavItem(index: 0, label: 'Home', iconPath:AppImages.home),
      _buildNavItem(index: 1, label: 'Quick Play', iconPath:AppImages.game),
      _buildNavItem(index: 2, label: 'Tournaments', iconPath: AppImages.tournament),
      _buildNavItem(index: 3, label: 'Wallet', iconPath: AppImages.wallet),
      _buildNavItem(index: 4, label: 'Profile', iconPath: AppImages.profile),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 80.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 4.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          color: Theme.of(context).primaryColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            return GestureDetector(
              onTap: () => onTap(index),
              child: items[index],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String iconPath,
  }) {
    final isSelected = currentIndex == index;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: label,
          child: svgIcon(
            name: iconPath,
            width: 26.w,
            height: 24.h,
            semanticsLabel: label,
            color: isSelected
                ? AppColors.brandYellowColor
                : const Color(0xff93C5FD),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: isSelected
              ? AppTextStyles.poppinsMedium.copyWith(
            fontSize: 13.sp,
            color: AppColors.brandYellowColor,
          )
              : AppTextStyles.poppinsMedium.copyWith(
            fontSize: 13.sp,
            color: const Color(0xff93C5FD),
          ),
        ),
      ],
    );
  }
}
