import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/providers/referral_provider.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';


class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralProvider>().getEarnings();
    });
    // _load();

  }


  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        appbarHeight: 50.h,
        leading: InkWell(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          child: Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back,
                size: 22.h,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        title: Center(
          child: Text(
            "Refer & Earn",
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: AppTextStyles.headingSmall.fontSize!.sp,
              color: AppColors.white,
            ),
          ),
        ),
        suffixIcon: Container(
          width: 25.w,
          height: 25.w,
          padding: const EdgeInsets.all(4.0),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
          ),
            child: Icon(
              Icons.question_mark,
              size: 12.h,
              color: Theme.of(context).colorScheme.primary,
            ),
        ),
        gradient: AppGradients.blueVertical,
      ),
      body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal.w,
              vertical: AppSpacing.section.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRewardIcon(),
                  SizedBox(height: AppSpacing.section.h),
                  Text(
                    "Ludo Smart",
                    style: AppTextStyles.poppinsBold.copyWith(
                      fontSize: AppTextStyles.headingLarge.fontSize!.sp,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Invite friends and earn amazing rewards!",
                    style: AppTextStyles.poppinsRegular.copyWith(
                      fontSize: AppTextStyles.body.fontSize!.sp,
                      color: const Color(0xffBFDBFE),
                    ),
                  ),
                  SizedBox(height: 26.h),
                  _buildEarnBox(),
                  SizedBox(height: 48.h),
                  _buildStats(),
                  SizedBox(height: 24.h),
                  _buildReferralCodeBox(),
                  SizedBox(height: 21.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "How it works",
                      style: AppTextStyles.poppinsSemiBold.copyWith(
                        fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  _buildStep(index: 1, title: "Share your code", desc: "Send your referral code to friends"),
                  _buildStep(index: 2, title: "Friend joins", desc: "They download and sign up using your code"),
                  _buildStep(index: 3, title: "Both get rewards", desc: "You earn ₹50, they get ₹30 bonus"),
                  SizedBox(height: 8.h),
                  CommonButton(
                    text: '',
                    btnTextColor: Colors.white,
                    btnChild: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        svgIcon(
                          name: AppImages.share,
                          width: 16.w,
                          height: 16.h,
                          color: Theme.of(context).colorScheme.primary,
                          semanticsLabel: 'share',
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Share with Friends',
                            style: AppTextStyles.poppinsBold.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                        )
                      ],
                    ),
                    onPressed: () {},
                  ),
                  SizedBox(height: 12.h),
                  CommonButton(
                    text: '',
                    btnTextColor: Theme.of(context).colorScheme.primary,
                    isBgColor: false,
                    btnBorder: Border.all(color: Theme.of(context).colorScheme.primary),
                    btnChild: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          svgIcon(
                            name: AppImages.history,
                            width: 16.w,
                            height: 16.h,
                            color: Theme.of(context).colorScheme.primary,
                            semanticsLabel: 'history',
                          ),
                        SizedBox(width: 8.w),
                        Text(
                          'View Referral History',
                            style: AppTextStyles.poppinsBold.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildRewardIcon() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Center(
          child: Container(
            height: 128.w,
            width: 128.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.gold,
            ),
            child: Center(
              child: svgIcon(
                name: AppImages.reward,
                width: 48.w,
                height: 48.h,
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: 'reward',
              ),
            ),
          ),
        ),
        Container(
          height: 32.w,
          width: 32.w,
          padding: EdgeInsets.all(6.w),
          margin: EdgeInsets.only(top: 8.h, right: 8.w),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandYellowColor,
          ),
          child: Tooltip(
            message: 'reward',
            child: Icon(
              Icons.star,
              size: 16.sp,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: 'reward star',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarnBox() {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        border: Border.all(color: const Color(0xff2563EB)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            "Earn ₹50 for each friend",
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: AppTextStyles.headingSmall.fontSize!.sp,
              color: AppColors.brandYellowColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Your friend gets ₹30 bonus too!",
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: AppTextStyles.body.fontSize!.sp,
              color: const Color(0xffBFDBFE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Consumer<ReferralProvider>(builder: (context, referralProvider, child) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 168 / 86,
        children: [
          _buildStatBox("Friends Invited", "${referralProvider.invitedFriends}"),
          _buildStatBox("Total Earned", "₹${referralProvider.totalEarning}"),
        ],
      );
    },);
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        border: Border.all(color: const Color(0xff2563EB)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.poppinsBold.copyWith(
              fontSize: AppTextStyles.headingLarge.fontSize!.sp,
              color: AppColors.brandYellowColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: AppTextStyles.body.fontSize!.sp,
              color: const Color(0xffBFDBFE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeBox() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal.w,
        vertical: 16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        border: Border.all(color: const Color(0xff2563EB)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Referral Code",
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: AppTextStyles.body.fontSize!.sp,
              color: const Color(0xffBFDBFE),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal.w),
            decoration: BoxDecoration(
              color: const Color(0xff1E40AF).withOpacity(0.4),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "LUDO2024",
                  style: AppTextStyles.poppinsBold.copyWith(
                    fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                    color: AppColors.brandYellowColor,
                  ),
                ),
                Row(
                  children: [
                    svgIcon(
                      name: AppImages.copy,
                      width: 14.w,
                      height: 14.h,
                      color: AppColors.brandYellowColor,
                      semanticsLabel: 'copy code',
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "COPY",
                      style: AppTextStyles.poppinsMedium.copyWith(
                        fontSize: AppTextStyles.body.fontSize!.sp,
                        color: AppColors.brandYellowColor,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required int index, required String title, required String desc}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32.w,
            width: 32.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.gold,
            ),
            child: Center(
              child: Text(
                "$index",
                  style: AppTextStyles.poppinsBold.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: AppTextStyles.body.fontSize!.sp,
                  ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.poppinsMedium.copyWith(
                    color: Colors.white,
                    fontSize: AppTextStyles.body.fontSize!.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  desc,
                  style: AppTextStyles.poppinsRegular.copyWith(
                    color: const Color(0xffBFDBFE),
                    fontSize: AppTextStyles.caption.fontSize!.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
