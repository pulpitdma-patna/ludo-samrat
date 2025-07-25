import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/common_widget/common_textfield.dart';
import 'package:frontend/providers/kyc_provider.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/theme.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_drawer.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      context.read<KycProvider>().setDocument(picked);
    }
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KycProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KycProvider>(
      builder: (context, kycProvider, _) {
        return AppScaffold(
          isLoading: kycProvider.isLoading,
          drawer: const AppDrawer(),
          appBar: GradientAppBar(
            leading: InkWell(
              onTap: () => Navigator.pop(context),
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
                  'KYC Verification',
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(16.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please upload your document below to verify your identity.',
                    style: AppTextStyles.poppinsMedium.copyWith(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  GestureDetector(
                    onTap: _showPicker,
                    child: Container(
                      width: double.infinity,
                      height: 180.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: kycProvider.document != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.file(
                                File(kycProvider.document!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                'Tap to select document',
                                style: AppTextStyles.poppinsMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                    CommonButton(
                      width: double.infinity,
                      onPressed: () => kycProvider.submit(context),
                      btnBorder: Border.all(color: AppColors.white.withOpacity(0.2)),
                    btnChild: Text(
                      "Submit for Verification",
                      style: AppTextStyles.poppinsMedium.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  if (kycProvider.kycStatus == "pending")
                    CommonTextField(
                      width: double.infinity,
                      hintText: 'Status',
                      labelText: "Status",
                      labelStyle: AppTextStyles.poppinsLabel,
                      controller: TextEditingController(text: kycProvider.kycStatus),
                      prefixIcon: Icon(
                        kycProvider.kycStatus == 'verified'
                            ? Icons.check_circle
                            : Icons.info,
                        size: 26.h,
                        color: kycProvider.kycStatus == 'verified'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      readOnly: true,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

