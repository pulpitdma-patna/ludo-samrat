import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/common_widget/common_textfield.dart';
import 'package:frontend/common_widget/common_toast.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/wallet_provider.dart';
import 'package:frontend/localized_errors.dart';
import 'package:frontend/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
    });
  }

  final _transferFormKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        return AppScaffold(
          isLoading: walletProvider.isLoading,
          drawer: const AppDrawer(),
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
                  "Transfer",
                  textAlign: TextAlign.start,
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            suffixIcon: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellow, width: 2),
              ),
            ),
          ),
          backgroundGradient: AppGradients.walletCardGradient,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Wallet Balance
                  Text(
                    "Wallet Balance: ₹${walletProvider.totalAmount.toStringAsFixed(2)}",
                    style: AppTextStyles.poppinsSemiBold.copyWith(
                      fontSize: 20.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // KYC Pending Message
                  if (walletProvider.kycStatus == 'pending') ...[
                    CommonButton(
                      text: 'Complete KYC',
                      width: double.infinity,
                      btnTextColor: Colors.white,
                      btnBorder: Border.all(color: Colors.orange),
                      btnChild: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                "Please complete your KYC to transfer money.",
                                style: AppTextStyles.poppinsSemiBold.copyWith(
                                  color: AppColors.white,
                                  fontSize: AppTextStyles.body.fontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        context.push('/kyc');
                      },
                    ),
                    SizedBox(height: 16.h),
                      CommonButton(
                        text: 'Complete KYC',
                        width: double.infinity,
                        btnTextColor: Colors.white,
                      onPressed: () {
                        context.push('/kyc');
                      },
                    ),
                  ],

                  // Transfer Form (if KYC completed)
                  if (walletProvider.kycStatus != 'pending') ...[
                    Form(
                      key: _transferFormKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          CommonTextField(
                            width: double.infinity,
                            controller: walletProvider.amountController,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter amount',
                            prefixIcon: const Icon(Icons.currency_rupee, color: Colors.white),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Amount is required';
                              }
                              final amount = int.tryParse(value.trim());
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          CommonTextField(
                            width: double.infinity,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            hintText: 'Recipient Phone',
                            prefixIcon: const Icon(Icons.phone, color: Colors.white),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              final v = value.trim();
                              if (v.length < 10) {
                                return 'Enter a valid phone';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12.h),
                          CommonButton(
                            width: double.infinity,
                            onPressed: () async {
                              if (_phoneController.text.trim().length < 10) {
                                CommonToast.error('Enter a valid phone number');
                                return;
                              }
                              final res = await walletProvider.verifyRecipientPhone(
                                  _phoneController.text.trim(), context);
                              if (res.isSuccess) {
                                CommonToast.success('Verified');
                              } else {
                                final msg = localizeError(res.code, res.error!);
                                CommonToast.error(msg);
                              }
                            },
                            btnChild: Text(
                              'Verify',
                              style: AppTextStyles.poppinsMedium.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          if (walletProvider.recipientName != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Recipient: ${walletProvider.recipientName}',
                              style: AppTextStyles.poppinsSemiBold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    CommonButton(
                      width: double.infinity,
                      onPressed: () {
                        if (_transferFormKey.currentState!.validate()) {
                          final id = walletProvider.recipientId;
                          if (id == null) {
                            CommonToast.error('Verify recipient phone');
                            return;
                          }
                          walletProvider.transfer(id, context);
                        }
                      },
                      btnChild: Text(
                        "Transfer",
                        style: AppTextStyles.poppinsMedium.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        );
      },
    );
  }
}
