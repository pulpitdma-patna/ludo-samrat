import 'package:flutter/material.dart';
import 'package:frontend/app_images.dart';
import '../theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OtpLogin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final bool loading;
  final VoidCallback onSendOtp;
  final VoidCallback onLogin;
  final VoidCallback onFieldChanged;
  final VoidCallback onFacebook;
  final VoidCallback onSignup;

  const OtpLogin({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    required this.loading,
    required this.onSendOtp,
    required this.onLogin,
    required this.onFieldChanged,
    required this.onFacebook,
    required this.onSignup,
  });

  Widget _buildField(BuildContext context, TextEditingController controller,
      String label,
      {TextInputType? keyboardType, IconData? icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.poppins,
      decoration: InputDecoration(
        prefixIcon:
            icon != null ? Icon(icon, color: Theme.of(context).colorScheme.onBackground) : null,
        labelText: label,
        labelStyle: AppTextStyles.poppinsLabel,
        filled: true,
        fillColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3)),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      onChanged: (_) => onFieldChanged(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(AppImages.auth, fit: BoxFit.cover),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppImages.logo, height: 120),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 50,
                          offset: Offset(0, 25),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          context,
                          phoneController,
                          'Mobile Number',
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone,
                        ),
                        if (otpSent) ...[
                          const SizedBox(height: 12),
                          _buildField(
                            context,
                            otpController,
                            'OTP',
                            keyboardType: TextInputType.number,
                            icon: Icons.sms,
                          ),
                        ],
                        const SizedBox(height: 20),
                        loading
                            ? const CircularProgressIndicator()
                            : otpSent
                                ? ElevatedButton(
                                    onPressed:
                                        phoneController.text.isNotEmpty &&
                                                otpController.text.isNotEmpty
                                            ? onLogin
                                            : null,
                                    child: Text(
                                      'SIGN IN',
                                      style: AppTextStyles.poppinsBold,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: phoneController.text.isNotEmpty
                                        ? onSendOtp
                                        : null,
                                    child: Text(
                                      'SEND OTP',
                                      style: AppTextStyles.poppinsBold,
                                    ),
                                  ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onFacebook,
                    child: const Text('Facebook'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTextStyles.poppins.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: onSignup,
                        child: const Text(
                          ' Sign Up',
                          style: AppTextStyles.poppinsBold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ],
);
  }
}
