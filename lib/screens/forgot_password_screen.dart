import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:frontend/utils/validate.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/auth/auth_card.dart';
import 'package:frontend/common_widget/auth/auth_header.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/common_widget/auth/auth_footer.dart';
import 'package:frontend/common_widget/common_textfield.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/public_settings_provider.dart';
import '../theme.dart';
import '../localized_errors.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _otpSent = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await context
        .read<AuthProvider>()
        .forgotPassword(_phoneController.text);
    if (result.isSuccess) {
      setState(() {
        _otpSent = true;
      });
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

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await context.read<AuthProvider>().changePassword(
      _phoneController.text,
      _passwordController.text,
      _otpController.text,
    );
    if (result.isSuccess) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password updated')));
      context.go('/login');
    } else {
      final msg = localizeError(result.code, result.error!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }


  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<PublicSettingsProvider>().backgroundImageUrl;
    return AppScaffold(
        resizeToAvoidBottomInset: true,
        backgroundImageUrl: bgUrl,
        backgroundImage: bgUrl == null ? AppImages.forgotPassword : null,
        body: SafeArea(
            child: SingleChildScrollView(
              child: Stack(children: [
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 62.h),
                        AuthHeader(logoWidth: authLogoWidth),
                        SizedBox(height: 16.h),
                        AuthCard(
                          height: _otpSent ? 555.h : 420.h,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              vertical: 12.h, horizontal: 33.w),
                          color: Colors.white.withOpacity(0.15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forgot Password?',
                                style: AppTextStyles.poppinsBold.copyWith(
                                  color: Colors.white,
                                  fontSize: 30.sp,
                                ),
                              ),
                              SizedBox(
                                height: 8.h,
                              ),
                              Text(
                                'Enter your mobile number and we\'ll send you a verification code to reset your password',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.poppinsRegular.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 32.h),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mobile Number',
                                    style: AppTextStyles.poppinsMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: AppTextStyles.body.fontSize!.sp,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 8.h,
                                  ),
                                  CommonTextField(
                                    hintText: 'Enter your mobile number',
                                    prefixIcon: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        svgIcon(
                                            name: AppImages.mobile,
                                            width: 13.5.w,
                                            height: 18.h,
                                            color: AppColors.brandYellow),
                                      ],
                                    ),
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => validatePhone(v ?? ''),
                                  onChanged: (_) => setState(() {}),
                                ),
                                ],
                              ),
                              if (_otpSent) ...[
                                SizedBox(height: 12.h),
                                CommonTextField(
                                  hintText: 'New Password',
                                  prefixIcon: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      svgIcon(
                                          name: AppImages.password,
                                          width: 13.5.w,
                                          height: 18.h,
                                          color: AppColors.brandYellow),
                                    ],
                                  ),
                                  controller: _passwordController,
                                  obscureText: true,
                                  validator: (v) => validatePassword(v ?? ''),
                                  onChanged: (_) => setState(() {}),
                                ),
                                SizedBox(height: 12.h),
                                CommonTextField(
                                  hintText: 'OTP',
                                  prefixIcon: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      svgIcon(
                                          name: AppImages.mobile,
                                          width: 13.5.w,
                                          height: 18.h,
                                          color: AppColors.brandYellow),
                                    ],
                                  ),
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => validateOtp(v ?? ''),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                              SizedBox(height: 20.h),
                              context.watch<AuthProvider>().isLoading
                                  ? const CircularProgressIndicator()
                                  : CommonButton(
                                      width: 276.w,
                                      btnChild: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          svgIcon(
                                              name: AppImages.send,
                                              width: 13.5.w,
                                              height: 18.h,
                                              color: Colors.white),
                                          SizedBox(
                                            width: 10.w,
                                          ),
                                          Text(
                                            _otpSent
                                                ? 'RESET PASSWORD'
                                                : 'Send Verification Code',
                                            style: AppTextStyles.poppinsSemiBold
                                                .copyWith(
                                                    color: Colors.white,
                                                    fontSize: 16.sp),
                                          ),
                                        ],
                                      ),
                                      onPressed: () {
                                        if (_otpSent) {
                                          if (_phoneController.text.isNotEmpty &&
                                              _otpController.text.isNotEmpty &&
                                              _passwordController.text.isNotEmpty) {
                                            _changePassword();
                                          }
                                        } else {
                                          if (_phoneController.text.isNotEmpty) {
                                            _sendCode();
                                          }
                                        }
                                      },
                                    ),
                              SizedBox(height: 26.h),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: AuthFooter(
                            actionText: 'Back to Login',
                            onTap: () => context.go('/login'),
                            isBack: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ]),
              ),
            ),
          );

  }
}
