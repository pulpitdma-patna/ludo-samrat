import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../common_widget/app_scaffold.dart';
import '../common_widget/common_appbar.dart';
import '../widgets/transaction_row.dart';
import '../widgets/app_drawer.dart';
import '../providers/wallet_provider.dart';
import '../utils/svg_icon.dart';
import '../app_images.dart';
import '../theme.dart';
import '../utils/transaction_utils.dart';
import '../utils/date_utils.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        final transactions = wallet.transactions;
        return AppScaffold(
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
                  'Transaction History',
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          body: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index] as Map<String, dynamic>? ?? {};
              final status = tx['status']?.toString() ?? '';
              final type = tx['type']?.toString() ?? '';
              final createdAt = formatTimestamp(
                  tx['created_at']?.toString() ?? '');
              final amount = parseAmount(tx['amount']);
              final iconPath = _iconForType(type);
              return TransactionRow(
                leading: _buildTransactionIcon(
                  iconPath: iconPath,
                  label: type,
                  status: status,
                ),
                title: type.isNotEmpty
                    ? type[0].toUpperCase() + type.substring(1)
                    : 'Transaction',
                subtitle: createdAt,
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
        );
      },
    );
  }

  Widget _buildTransactionIcon({required String iconPath, required String label, required String status}) {
    return Container(
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

}

