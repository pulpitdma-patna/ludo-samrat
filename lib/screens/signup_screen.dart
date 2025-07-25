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
import 'package:frontend/utils/validate.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/public_settings_provider.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _send() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await context.read<AuthProvider>().signup(
        _phoneController.text,
        _passwordController.text,
        _fullNameController.text.isNotEmpty ? _fullNameController.text : null,
        _referralController.text.isNotEmpty ? _referralController.text : null);
    if (result.isSuccess) {
      if (result.data != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('OTP: ${result.data!}')));
      }
      final phone = Uri.encodeComponent(_phoneController.text);
      if (mounted) context.push('/verify/$phone');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
  }


  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<PublicSettingsProvider>().backgroundImageUrl;
    return AppScaffold(
      backgroundImageUrl: bgUrl,
      backgroundImage: bgUrl == null ? AppImages.signup : null,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
            child: Stack(
              children: [
              Positioned.fill(
                child: Image.asset(
                  AppImages.bg_signup_small_dot,
                ),
              ),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 58.h),
                        AuthHeader(logoWidth: authLogoWidth),
                        // SizedBox(height: 29.h),
                        AuthCard(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 33.w, vertical: 25.h),
                          child: Column(
                            children: [
                              Text(
                                'Join the Royal Game',
                                style: AppTextStyles.poppinsMedium.copyWith(
                                  color: const Color(0xFFFCD34D),
                                  fontSize: AppTextStyles.headingLarge.fontSize!.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                               SizedBox(height: 24.sp),
                              CommonTextField(
                                hintText: '',
                                labelText: 'Full Name',
                                labelStyle: AppTextStyles.poppinsLabel,
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: AppColors.brandYellow),
                                controller: _fullNameController,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              CommonTextField(
                                hintText: '',
                                labelText: 'Mobile Number',
                                labelStyle: AppTextStyles.poppinsLabel,
                                prefixIcon: const Icon(Icons.phone,
                                    color: AppColors.brandYellow),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: (v) => validatePhone(v ?? ''),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              CommonTextField(
                                hintText: '',
                                labelText: 'Password',
                                labelStyle: AppTextStyles.poppinsLabel,
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppColors.brandYellow),
                                controller: _passwordController,
                                obscureText: true,
                                validator: (v) => validatePassword(v ?? ''),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              CommonTextField(
                                hintText: '',
                                labelText: 'Referral Code (Optional)',
                                labelStyle: AppTextStyles.poppinsLabel,
                                prefixIcon: const Icon(Icons.card_giftcard,
                                    color: AppColors.brandYellow),
                                controller: _referralController,
                                validator: (v) => null,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 20),

                              context.watch<AuthProvider>().isLoading
                                  ? const CircularProgressIndicator() :
                              CommonButton(
                                text: 'Login Now',
                                btnTextColor: Colors.white,
                                btnChild: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      SvgPicture.asset(
                                        AppImages.crown,
                                        height: 20,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    SizedBox(width: 8.w,),
                                    Text(
                                      'CREATE ACCOUNT',
                                      style: AppTextStyles.poppins.copyWith(
                                        color: AppColors.brandPrimary,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  ],
                                ),
                                onPressed: () {
                                  if( _phoneController.text.isNotEmpty &&
                                      _passwordController.text.isNotEmpty){
                                    _send();
                                  }
                                },
                              ),

                            /*  context.watch<AuthProvider>().isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton.icon(
                                onPressed: _phoneController.text.isNotEmpty &&
                                    _passwordController.text.isNotEmpty
                                    ? _send
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFBBF24),
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                                icon: SvgPicture.asset(
                                  'assets/crown.svg',
                                  height: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  'CREATE ACCOUNT',
                                  style: AppTextStyles.poppinsBold,
                                ),
                              ),*/
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
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Text(
                        //       'Already have an account?',
                        //       style: AppTextStyles.poppins.copyWith(
                        //         color: Colors.white.withOpacity(0.8),
                        //         fontSize: 16,
                        //       ),
                        //     ),
                        //     TextButton(
                        //       onPressed: () => context.go('/login'),
                        //       child: Text(
                        //         ' Sign In',
                        //         style: AppTextStyles.poppinsBold.copyWith(
                        //           color: const Color(0xFFFBBF24),
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w600,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  )
                ]
            ),
          ),

      ),
    );
  }
}
