import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/common_widget/common_textfield.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/auth/auth_card.dart';
import 'package:frontend/common_widget/auth/auth_header.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:frontend/utils/validate.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../localized_errors.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/public_settings_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _seconds = 119;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 119;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final result =
        await context.read<AuthProvider>().sendOtp(widget.phoneNumber);
    setState(() => _resending = false);
    if (result.isSuccess) {
      _startTimer();
      if (result.data != null) {
        _otpController.text = result.data!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('OTP: ${result.data!}')));
      }
    } else {
      final msg = localizeError(result.code, result.error!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _verify() async {
    final err = validateOtp(_otpController.text);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final fcm = await FirebaseMessaging.instance.getToken();
    final result = await context
        .read<AuthProvider>()
        .login(widget.phoneNumber, _otpController.text, fcmToken: fcm);

    if (result.isSuccess) {
      if (mounted) {
        await AppPreferences().setIsLoggedIn(true);
        final isLogin = await AppPreferences().getIsLoggedIn();
        log('Login state: $isLogin');
        context.go('/dashboard');
      }
    } else {
      final msg = localizeError(result.code, result.error!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  PinTheme isPinTheme = PinTheme(
    height: 50.h,
    width: 50.w,
    padding: EdgeInsets.zero,
    decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: AppColors.pinPutBorderColor.withOpacity(0.3), width: 2.w)),
    textStyle: AppTextStyles.poppinsSemiBold.copyWith(
      color: const Color(0xffFDE047),
      fontSize: 16.sp,
    ),
    margin: EdgeInsets.zero,
  );

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<PublicSettingsProvider>().backgroundImageUrl;
    return AppScaffold(
      backgroundImageUrl: bgUrl,
      backgroundImage: bgUrl == null ? AppImages.bg_square_otp : null,
      body: SafeArea(
          child: Stack(
            children: [
            Positioned.fill(
              child: Image.asset(
                AppImages.bg_small_circle_otp,
              ),
            ),
          // Positioned(
          //   top: 51.h,
          //   child: Container(
          //     color: Colors.transparent,
          //     width: 390.w,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Image.asset(
          //           'assets/logo.png',
          //           width: 164.w,
          //           fit: BoxFit.cover,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Positioned(
            // top: 51.h,
            bottom: 8.h,
            left: 8.w,
            right: 8.w,
            child: Container(
              // color: Colors.red,
              // height: 1.sh,
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    color: Colors.transparent,
                    child: AuthHeader(logoWidth: authLogoWidth),
                  ),
                  Stack(
                    children: [
                      AuthCard(
                        height: 568.h,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        margin: EdgeInsets.only(bottom: 8.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 39.h,
                            ),
                            Text(
                              'Enter OTP',
                              style: AppTextStyles.poppinsBold.copyWith(
                                fontSize: AppTextStyles.headingLarge.fontSize!.sp,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "We've sent a 6-digit code to",
                              style: AppTextStyles.poppinsRegular.copyWith(
                                color: AppColors.white.withOpacity(0.5),
                                fontSize: AppTextStyles.body.fontSize!.sp,
                              ),
                            ),
                            Text(
                              "+91 ${widget.phoneNumber}",
                              style: AppTextStyles.poppinsSemiBold.copyWith(
                                color: Color(0xffFDE047),
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(
                              height: 124.h,
                            ),
                            Text(
                              "Didn't receive the code?",
                              style: AppTextStyles.poppinsRegular.copyWith(
                                color: AppColors.white.withOpacity(0.5),
                                fontSize: AppTextStyles.body.fontSize!.sp,
                              ),
                            ),
                            if (_seconds <= 0)
                              TextButton(
                                onPressed: () {
                                  if (!_resending) {
                                    _resend();
                                  }
                                },
                                child: Text(
                                  'Resend OTP',
                                  style: AppTextStyles.poppinsSemiBold.copyWith(
                                    color: const Color(0xffFDE047),
                                    fontSize: AppTextStyles.body.fontSize!.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: null,
                                child: Text(
                                  'Resend OTP',
                                  style: AppTextStyles.poppinsSemiBold.copyWith(
                                    color: AppColors.white.withOpacity(0.5),
                                    fontSize: AppTextStyles.body.fontSize!.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 20.h,
                            ),
                            context.watch<AuthProvider>().isLoading
                                ? const CircularProgressIndicator()
                                : CommonButton(
                                    text: 'Login Now',
                                    btnTextColor: Colors.white,
                                    btnChild: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        svgIcon(
                                          name: AppImages.loginNow,
                                          height: 16.h,
                                          width: 16.w,
                                        ),
                                        SizedBox(
                                          width: 8.w,
                                        ),
                                        Text(
                                          'Verify & Login',
                                          style: AppTextStyles.poppins.copyWith(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      ],
                                    ),
                                    onPressed: _verify,
                                  ),
                            SizedBox(
                              height: 25.h,
                            ),
                            IgnorePointer(
                              ignoring: context.watch<AuthProvider>().isLoading
                                  ? true
                                  : false,
                              child: CommonButton(
                                text: 'Change Number',
                                btnTextColor: Colors.white,
                                isBgColor: false,
                                btnBorder: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 2.w,
                                ),
                                btnChild: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    svgIcon(
                                        name: AppImages.edit,
                                        width: 16.w,
                                        height: 16.h,
                                        color: AppColors.white),
                                    SizedBox(
                                      width: 8.w,
                                    ),
                                    Text(
                                      'Change Number',
                                      style: AppTextStyles.poppins.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  ],
                                ),
                                onPressed: () {
                                  if (context.canPop()) context.pop();
                                },
                              ),
                            ),
                            SizedBox(
                              height: 18.h,
                            ),
                            if (_seconds > 0)
                              Container(
                                height: 40.h,
                                width: 167.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: const Offset(0, 25),
                                      blurRadius: 50,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    svgIcon(
                                        name: AppImages.clock,
                                        width: 16.w,
                                        height: 16.h,
                                        color: AppColors.brandYellow),
                                    Text(
                                      " Resend in ",
                                      style:
                                          AppTextStyles.poppinsRegular.copyWith(
                                        color: AppColors.white.withOpacity(0.5),
                                        fontSize: AppTextStyles.body.fontSize!.sp,
                                      ),
                                    ),
                                    Text(
                                      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                                      style:
                                          AppTextStyles.poppinsSemiBold.copyWith(
                                        color: const Color(0xffFDE047),
                                        fontSize: AppTextStyles.body.fontSize!.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                      Positioned(
                        top: 163.h,
                        left: 16.w,
                        right: 16.w,
                        child: Pinput(
                          length: 6,
                          defaultPinTheme: isPinTheme,
                          focusedPinTheme: isPinTheme,
                          submittedPinTheme: isPinTheme,
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          pinAnimationType: PinAnimationType.slide,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          animationDuration: const Duration(milliseconds: 300),
                          isCursorAnimationEnabled: true,
                          showCursor: true,
                          onChanged: (value) {},
                          onCompleted: (value) => _verify(),
                          closeKeyboardWhenCompleted: true,
                          cursor: Container(
                            width: 2,
                            height: 1,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
