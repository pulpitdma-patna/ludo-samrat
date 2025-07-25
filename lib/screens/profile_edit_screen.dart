import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/common_widget/common_textfield.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  XFile? _avatar;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _nameController.text = profile.name ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _avatar = picked);
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final success = await context.read<ProfileProvider>().updateProfile(
      name: _nameController.text,
      password:
          _passwordController.text.isNotEmpty ? _passwordController.text : null,
      avatar: _avatar,
    );
    if (success && mounted) {
      if (context.canPop()) context.pop();
    } else if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: GradientAppBar(
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
        title: Row(
          children: [
            Text(
              'Edit Profile',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 18.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Consumer<ProfileProvider>(
            builder: (context, profile, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 96.w,
                          height: 96.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: _avatar != null
                                  ? FileImage(File(_avatar!.path))
                                  : (profile.avatarUrl != null &&
                                          profile.avatarUrl!.isNotEmpty
                                      ? NetworkImage(profile.avatarUrl!)
                                      : const AssetImage(AppImages.temp_logo))
                                  as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showPicker,
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20.w,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  CommonTextField(
                    hintText: '',
                    labelText: 'Full Name',
                    labelStyle: AppTextStyles.poppinsLabel,
                    controller: _nameController,
                  ),
                  SizedBox(height: 12.h),
                  CommonTextField(
                    hintText: '',
                    labelText: 'Phone Number',
                    labelStyle: AppTextStyles.poppinsLabel,
                    controller: _phoneController,
                    readOnly: true,
                  ),
                  SizedBox(height: 12.h),
                  CommonTextField(
                    hintText: '',
                    labelText: 'Password',
                    labelStyle: AppTextStyles.poppinsLabel,
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  SizedBox(height: 24.h),
                    CommonButton(
                      btnChild: Text(
                        'Save',
                        style: AppTextStyles.poppinsSemiBold.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16.sp,
                        ),
                      ),
                      onPressed: _save,
                    )
                ],
              );
            },
          ),
        ),
    );
  }
}
