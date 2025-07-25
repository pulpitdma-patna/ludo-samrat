import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/theme_mode_switch.dart';
import '../providers/wallet_provider.dart';
import '../utils/svg_icon.dart';
import '../app_images.dart';
import '../theme.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  final Widget? leading;
  final Widget? title;
  final Widget? suffixIcon;
  final Gradient? gradient;
  final double? appbarHeight;
  final bool showThemeSwitch;
  final bool showWalletBalance;

   GradientAppBar({
    Key? key,
    this.leading,
    this.title,
    this.suffixIcon,
    this.gradient,
    this.appbarHeight,
    this.showThemeSwitch = false,
    this.showWalletBalance = true,
  })  : preferredSize = Size.fromHeight(appbarHeight ?? 70.h),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).appBarTheme.backgroundColor;
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? bgColor : null,
        gradient: gradient,
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black54,
        //     blurRadius: 8,
        //     offset: Offset(0, 4),
        //   ),
        // ],
        // borderRadius: BorderRadius.only(
        //   bottomLeft: Radius.circular(10),
        //   bottomRight: Radius.circular(10),
        // ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w,),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leading ?? const SizedBox(),
              Expanded(
                child: Center(child: title ?? const SizedBox()),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showWalletBalance)
                    GestureDetector(
                      onTap: () => context.push('/dashboard?tab=3'),
                      child: Row(
                        children: [
                          svgIcon(
                            name: AppImages.wallet,
                            width: 24.w,
                            height: 24.w,
                            color: Theme.of(context).appBarTheme.foregroundColor,
                            semanticsLabel: 'wallet',
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '₹${context.watch<WalletProvider>().totalAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.poppinsMedium.copyWith(
                              fontSize: 14.sp,
                              color: Theme.of(context).appBarTheme.foregroundColor,
                            ),
                          ),
                          SizedBox(width: 12.w),
                        ],
                      ),
                    ),
                  if (suffixIcon != null) suffixIcon!,
                  if (showThemeSwitch) const ThemeModeSwitch(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
