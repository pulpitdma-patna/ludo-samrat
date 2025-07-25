import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_toast.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/utils/svg_icon.dart';
import '../localized_errors.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/transaction_row.dart';
import '../config.dart';
import '../services/tutorial_storage.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';
import '../common_widget/common_button.dart';
import 'package:go_router/go_router.dart';
import '../utils/transaction_utils.dart';
import '../utils/date_utils.dart';



class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  bool _showTutorial = false;

  void _checkTutorial() async {
    final seen = await TutorialStorage.hasSeenFeature('wallet');
    if (!seen) setState(() => _showTutorial = true);
  }

  void _dismissTutorial() async {
    await TutorialStorage.setFeatureSeen('wallet');
    setState(() => _showTutorial = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WalletProvider>();
      provider.load();
      provider.loadTransactions();
    });
    _checkTutorial();
  }





  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
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
            Expanded(
              child: Text(
                "Wallet",
                textAlign: TextAlign.start,
                style: AppTextStyles.poppinsSemiBold.copyWith(
                  fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        suffixIcon: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow, width: 2),
          ),
        ),
      ),
      body: Consumer(
        builder: (context, walletProvider,_) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              SizedBox(height: 20.h),
              _buildQuickActions(),
              SizedBox(height: 28.h),
              _buildTransactionHistory(),
              SizedBox(height: 40.h), // Space for bottom nav
            ],
          ),
        );
      },),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer<WalletProvider>(builder: (context, wallet,_) {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          gradient: AppGradients.walletCardGradient,
          border: Border.all(color: const Color(0xffD4AF37).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Balance", style:AppTextStyles.poppinsMedium.copyWith(
              fontSize: AppTextStyles.body.fontSize!.sp,
              color: const Color(0xffF0D078),
            )),
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: "₹",
                      style:  AppTextStyles.poppinsBold.copyWith(
                        fontSize: 30.sp,
                        color: const Color(0xffF0D078),
                      ),
                      children: [
                        TextSpan(
                          text: "${wallet.totalAmount.toStringAsFixed(2)}",
                          style:  AppTextStyles.poppinsBold.copyWith(
                            fontSize: 30.sp,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 36.w,
                  height: 44.h,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                      color: const Color(0xffD4AF37).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18.r)
                  ),
                  child: svgIcon(
                    name: AppImages.coin,
                    width: 14.w,
                    height: 14.h,
                    color: AppColors.gold,
                    semanticsLabel: 'coins',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },);
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
          Expanded(
            child: CommonButton(
              width: double.infinity,
              onPressed: () {
                context.push('/deposit');
              },
            btnChild: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                svgIcon(
                  name: AppImages.add,
                  width: 13.w,
                  height: 13.h,
                  color: AppColors.gold,
                  semanticsLabel: 'add money',
                ),
                SizedBox(width: 8.w,),
                Flexible(
                  child: Text(
                    "Add Money",
                    style: AppTextStyles.poppinsMedium.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CommonButton(
            width: double.infinity,
            onPressed: () {
              context.push('/transfer');
            },
            btnChild: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                svgIcon(
                  name: AppImages.send,
                  width: 13.w,
                  height: 13.h,
                  color: AppColors.gold,
                  semanticsLabel: 'transfer',
                ),
                SizedBox(width: 8.w,),
                Flexible(
                  child: Text(
                    "Transfer",
                    style: AppTextStyles.poppinsMedium.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CommonButton(
            width: double.infinity,
            onPressed: () {
              context.push('/withdraw');
            },
            btnChild: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                svgIcon(
                  name: AppImages.withdraw,
                  width: 13.w,
                  height: 13.h,
                  color: AppColors.gold,
                  semanticsLabel: 'withdraw',
                ),
                SizedBox(width: 8.w,),
                Flexible(
                  child: Text(
                    "Withdraw",
                    style: AppTextStyles.poppinsMedium.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTransactionHistory() {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        final transactions = wallet.transactions ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25.h),
            _selectionHeader(
              title: "Transaction History",
              showViewAll: transactions.isNotEmpty,
              onViewAll: () {
                context.push('/wallet/transactions');
              },
            ),
            SizedBox(height: 12.h),

            if (transactions.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 13.h),
                decoration: BoxDecoration(
                  color: const Color(0xff0F2C8B).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xffD4AF37).withOpacity(0.1),
                  ),
                ),
                child: ListView.separated(
                  itemCount: transactions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];

                    final type = tx['type']?.toString() ?? '';
                    final subtitle = formatTimestamp(
                        tx['created_at']?.toString() ?? '');
                    final amount = parseAmount(tx['amount']);
                    final status = tx['status']?.toString() ?? 'default';
                    final icon = _iconForType(type);

                    return TransactionRow(
                      leading: _buildTransactionIcon(
                        iconPath: icon,
                        label: type,
                        status: status,
                      ),
                      title: type.isNotEmpty
                          ? type[0].toUpperCase() + type.substring(1)
                          : 'Transaction',
                      subtitle: subtitle,
                      amount: '₹${amount.toStringAsFixed(2)}',
                      amountColor: getTransactionColor(status),
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      borderRadius: BorderRadius.circular(12.r),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(
                    height: 1.0,
                    color: Color(0xff1438A6),
                    thickness: 1.0,
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text(
                    'No transactions available',
                    style: AppTextStyles.poppinsRegular.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }


  Widget _buildTransactionIcon({required String iconPath, required String label,required String status}) {
    return Column(
      children: [
        Container(
          height: 40.w,
          width: 40.w,
          padding: EdgeInsets.symmetric(horizontal: 11.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: getStatusColor(status).withOpacity(0.2),
          ),
          child: Tooltip(
            message: label,
            child: svgIcon(
              name: iconPath,
              width: 12.w,
              height: 12.h,
              semanticsLabel: label,
              color: getStatusColor(status),
            ),
          ),
        ),
      ],
    );
  }


  String _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
        return AppImages.credit;
      case 'debit':
        return AppImages.debit;
      case 'add':
      case 'deposit':
        return AppImages.add;
      case 'withdraw':
        return AppImages.withdraw;
      case 'transfer_in':
        return AppImages.credit;
      case 'transfer_out':
        return AppImages.debit;
      case 'lost':
        return AppImages.lostGame;
      case 'reward':
        return AppImages.reward;
      case 'tournament':
        return AppImages.tournament;
      case 'won':
        return AppImages.coin;
      default:
        return AppImages.coin;
    }
  }

  Widget _selectionHeader({
    required String title,
    required bool showViewAll,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 16.sp,
                color: const Color(0xffF0D078),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                "See All",
                style: AppTextStyles.poppinsMedium.copyWith(
                  fontSize: AppTextStyles.body.fontSize!.sp,
                  color: const Color(0xffF0D078),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }




}
