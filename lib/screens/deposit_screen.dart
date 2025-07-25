import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/common_widget/common_textfield.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/localized_errors.dart';
import 'package:frontend/providers/wallet_provider.dart';
import 'package:frontend/widgets/app_drawer.dart';
import 'package:frontend/common_widget/common_toast.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config.dart';
import '../theme.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';

const List<int> kPresetAmounts = [50, 100, 500, 1000, 2000, 5000];

class DepositScreen extends StatefulWidget {
  final double? amount;
  const DepositScreen({super.key, this.amount});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final Razorpay _razorpay = Razorpay();
  int? _selectedMethodId;
  int? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.amount != null && widget.amount! > 0
            ? widget.amount!.toInt().toString()
            : '');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wallet = context.read<WalletProvider>();
      wallet.load();
      await wallet.loadPaymentMethods();
      if (mounted) {
        setState(() {
          _selectedMethodId =
              wallet.paymentMethods.isNotEmpty ? wallet.paymentMethods.first['id'] as int : null;
        });
      }
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (_) async {
      await context.read<WalletProvider>().load();
      await context.read<WalletProvider>().loadTransactions();
      if (context.canPop()) context.pop();
      CommonToast.success('Deposit successful');
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (_) {
      if (context.canPop()) context.pop();
      CommonToast.error('Payment failed');
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {
      CommonToast.error('External wallet not supported');
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _deposit() async {
    final value =
        double.tryParse(_amountController.text.isEmpty ? '10' : _amountController.text);
    if (value == null || value <= 0) {
      CommonToast.warning('Please enter a valid amount');
      return;
    }
    if (_selectedMethodId == null) {
      CommonToast.error('No payment methods available');
      return;
    }
    final result = await context
        .read<WalletProvider>()
        .deposit(value, _selectedMethodId!, context);
    if (result.isSuccess) {
      if (result.data != null && result.data!['gateway_id'] != null) {
        var options = {
          'key': razorpayKey,
          'order_id': result.data!['gateway_id'],
          'amount': (value * 100).toInt(),
          'name': 'Wallet Deposit',
        };
        _razorpay.open(options);
      } else {
        await context.read<WalletProvider>().load();
        await context.read<WalletProvider>().loadTransactions();
        if (context.canPop()) context.pop();
        CommonToast.success('Deposit successful');
      }
    } else {
      final msg = localizeError(result.code, result.error!);
      CommonToast.error(msg);
    }
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final selectedMethod = walletProvider.paymentMethods
            .cast<Map<String, dynamic>?>()
            .firstWhere((m) => m?['id'] == _selectedMethodId, orElse: () => null);
        final bankDetails = selectedMethod?['bank_details'] as String?;
        final qrUrl = selectedMethod?['qr_code_url'] as String?;
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
                  'Deposit',
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
                Text(
                  'Wallet Balance: ₹${walletProvider.totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 20.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.h),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                        width: double.infinity,
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        hintText: 'Enter amount',
                        prefixIcon:
                            const Icon(Icons.currency_rupee, color: Colors.white),
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
                        onChanged: walletProvider.onAmountChanged,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Payment Method',
                        style: AppTextStyles.poppinsMedium.copyWith(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 12.w,
                        children: walletProvider.paymentMethods.map((m) {
                          final id = m['id'] as int;
                          final provider = (m['provider'] ?? '').toString().toLowerCase();
                          final selected = _selectedMethodId == id;
                          IconData icon;
                          if (provider.contains('razorpay')) {
                            icon = Icons.credit_card;
                          } else {
                            icon = Icons.qr_code;
                          }
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMethodId = id),
                            child: Container(
                              width: 72,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selected ? AppColors.gold : Colors.white24),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: Colors.white),
                                  const SizedBox(height: 4),
                                  Text(
                                    m['name'] ?? '',
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (bankDetails != null && bankDetails.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SelectableText(
                                bankDetails,
                                style: AppTextStyles.poppinsRegular.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                                  tooltip: 'Copy',
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: bankDetails));
                                    CommonToast.success('Copied');
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                                  tooltip: 'Share',
                                  onPressed: () => Share.share(bankDetails),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      if (qrUrl != null && qrUrl.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Center(
                          child: Image.network(qrUrl, height: 200, fit: BoxFit.contain),
                        ),
                      ],
                      SizedBox(height: 12.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 12.w,
                          runSpacing: 8.h,
                          children: kPresetAmounts.map((amt) {
                            final isSelected = _selectedPreset == amt;
                            return SizedBox(
                              width: 90.w,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(isSelected ? 0.2 : 0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(
                                      color: isSelected ? AppColors.gold : Colors.white24),
                                ),
                                onPressed: () {
                                  setState(() => _selectedPreset = amt);
                                  _amountController.text = amt.toString();
                                  walletProvider.onAmountChanged(amt.toString());
                                },
                                child: Text('₹$amt'),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                CommonButton(
                  width: double.infinity,
                  onPressed: walletProvider.isInputValid ? _deposit : null,
                  btnChild: Text(
                    'Add',
                    style: AppTextStyles.poppinsMedium.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
