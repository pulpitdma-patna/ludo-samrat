import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/common_widget/common_textfield.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/auth/auth_card.dart';
import 'package:frontend/common_widget/auth/auth_header.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/common_widget/auth/auth_footer.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:frontend/utils/validate.dart';
import '../theme.dart';
import '../localized_errors.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/public_settings_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool visiblePassword = true;

  void _sendOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    final result =
    await context.read<AuthProvider>().sendOtp(_phoneController.text);
    if (result.isSuccess) {
      if (result.data != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('OTP: ${result.data!}')));
      }
      final phone = Uri.encodeComponent(_phoneController.text);
      if (mounted) context.push('/verify/$phone');
    } else {
      final msg = localizeError(result.code, result.error!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _loginWithNumberAndPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final fcm = await FirebaseMessaging.instance.getToken();
    final result = await context
        .read<AuthProvider>()
        .loginWithNumberAndPassword(_phoneController.text,_passwordController.text,fcmToken: fcm);
    if (result.isSuccess) {
      if (mounted) context.go('/dashboard');
    } else {
      final msg = "${result.error}";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }


  int currentTab = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<PublicSettingsProvider>().backgroundImageUrl;
    return AppScaffold(
      resizeToAvoidBottomInset: true,
      backgroundImageUrl: bgUrl,
      backgroundImage: bgUrl == null ? AppImages.bg_login : null,
      body: SafeArea(
        child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        AuthHeader(
                          headline: 'Welcome Back',
                          subtitle: 'Sign in to your account',
                          logoWidth: authLogoWidth,
                        ),
                        SizedBox(height: 32.h),
                        Container(
                          height: 54.h,
                          width: 342.w,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.white.withOpacity(0.2),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  currentTab = 0;
                                  setState(() {});
                                },
                                child: Container(
                                  height: 44.h,
                                  width: 166.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    gradient: currentTab == 0
                                        ? AppGradients.yellow
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Password',
                                      style: AppTextStyles.poppinsMedium.copyWith(
                                        color: AppColors.white,
                                        fontSize: AppTextStyles.body.fontSize!.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  currentTab = 1;
                                  setState(() {});
                                },
                                child: Container(
                                  height: 44.h,
                                  width: 166.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    gradient: currentTab == 1
                                        ? AppGradients.yellow
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'OTP',
                                      style: AppTextStyles.poppinsMedium.copyWith(
                                        color: AppColors.white,
                                        fontSize: AppTextStyles.body.fontSize!.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),
                        currentTab == 0 ? passwordLoginView() : otpLoginView(),
                        SizedBox(height: 16.h),
                        bottomTextView(),
                      ],
                    ),
                    ), // Padding
                  ), // SingleChildScrollView
                ), // SafeArea
              ); // AppScaffold
  }

  Widget passwordLoginView () {
    return Form(
      key: _passwordFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AuthCard(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          children: [
          CommonTextField(
            hintText: 'Mobile Number',
            prefixIcon: const Icon(Icons.phone_android, semanticLabel: 'phone number'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (v) => validatePhone(v ?? ''),
          ),
          SizedBox(height: 16.h),
          CommonTextField(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock, semanticLabel: 'password'),
            suffixIcon: visiblePassword ? Icons.visibility : Icons.visibility_off,
            onSuffixTap: () {
              visiblePassword =! visiblePassword;
              setState(() {});
            },
            obscureText: visiblePassword,
            controller: _passwordController,
            validator: (v) => validatePassword(v ?? ''),
          ),
        SizedBox(
          width: 342.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.poppinsMedium.copyWith(
                    color: AppColors.gradientYellowStart,
                    fontSize: AppTextStyles.body.fontSize!.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        context.watch<AuthProvider>().isLoading
            ? const CircularProgressIndicator() :
        CommonButton(
          text: 'Sign In',
          onPressed: () {
            _loginWithNumberAndPassword();
          },
        ),
        ],
      ),
    ),
  );
 }

  Widget otpLoginView () {
    return AuthCard(
      width: double.infinity,
      height: 307.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Form(
        key: _otpFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login with OTP',
              style: AppTextStyles.poppins.copyWith(
                fontSize: 20.sp,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            CommonTextField(
              hintText: 'Phone Number',
              prefixIcon: const Icon(
                Icons.phone_android,
                color: AppColors.brandYellow,
                semanticLabel: 'phone number',
              ),
              // prefixIcon: svgIcon(
              //     name: 'assets/mobile.svg',
              //     width: 10.5.w,
              //     height: 10.h,
              //     color: AppColors.brandYellow),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => validatePhone(v ?? ''),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 33.h),
            context.watch<AuthProvider>().isLoading
                ? const CircularProgressIndicator() :
              CommonButton(
                text: 'Login Now',
                btnTextColor: Colors.white,
              btnChild: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  svgIcon(
                    name: AppImages.loginNow,
                    height: 16.h,
                    width: 16.w,
                    semanticsLabel: 'login now',
                  ),
                  SizedBox(width: 8.w,),
                  Text(
                    'Login Now',
                    style: AppTextStyles.poppins.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
              onPressed: () {
                _sendOtp();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomTextView () {
    return AuthFooter(
      prefixText: currentTab == 0
          ? "Don't have an account? "
          : "New to Ludo King? ",
      actionText: currentTab == 0 ? 'Sign Up' : 'Create Account',
      onTap: () {
        context.push('/signup');
      },
    );
  }

}
