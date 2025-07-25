import 'package:flutter/material.dart';
import 'package:frontend/common_widget/common_toast.dart';
import 'package:frontend/localized_errors.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/services/kyc_api.dart';
import '../services/wallet_api.dart';
import '../services/api_result.dart';
import '../services/analytics_service.dart';
import '../utils/api_helpers.dart';

class WalletProvider extends ChangeNotifier {
  final WalletApi api;
  WalletProvider({WalletApi? api}) : api = api ?? WalletApi(){
    //
  }

  final TextEditingController amountController = TextEditingController();
  final TextEditingController upiController = TextEditingController();


  bool _inputValid = true;
  bool get isInputValid => _inputValid;

  bool _loading = false;
  bool get isLoading => _loading;

  List<dynamic> _paymentMethods = [];
  List<dynamic> get paymentMethods => _paymentMethods;

  String _kycStatus = "";
  String get kycStatus => _kycStatus;

  double _totalAmount = 0;
  double get totalAmount => _totalAmount;

  List<dynamic> _transactions = [];
  List<dynamic> get transactions => _transactions;

  int _userId = 0;
  int? _recipientId;
  String? _recipientName;
  int? get recipientId => _recipientId;
  String? get recipientName => _recipientName;

  Future<void> _updateBalance() async {
    final res = await api.balance();
    if (res.isSuccess && res.data != null) {
      _totalAmount = res.data!;
      notifyListeners();
    }
  }

  Future<void> load() async {
    _userId = await AppPreferences().getUserId();
    await _updateBalance();
    checkKycStatus();
    clearController();
  }

  Future<void> loadTransactions() async {
    _loading = true;
    notifyListeners();
    _transactions = await api.transactions();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadPaymentMethods() async {
    final res = await api.paymentMethods();
    if (res.isSuccess) {
      _paymentMethods =
          (res.data ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _paymentMethods = [];
    }
    notifyListeners();
  }

  Future<ApiResult<Map<String, dynamic>>> deposit(
      double amount, int methodId, BuildContext ctx) async {
    _loading = true;
    notifyListeners();
    final res = await api.deposit(amount, methodId);
    await handleAuthError(res, ctx);
    if (res.isSuccess) {
      await AnalyticsService.logWalletTransaction('deposit', amount);
    }
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<void> withdraw(BuildContext context) async {
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      CommonToast.error("Enter a valid amount");
      return;
    }
    if (!upiController.text.contains('@') || upiController.text.length < 5) {
        CommonToast.error("Please enter a valid UPI ID");
      return;
    }
    final res = await api.withdraw(double.parse(amountController.text));
    await handleAuthError(res, context);
    if (res.isSuccess) {
      CommonToast.success("Withdrawal successful");
      await _updateBalance();
    } else {
      final msg = localizeError(res.code, res.error!);
      CommonToast.error(msg);
    }
    await loadTransactions();
    clearAmount();
  }

  Future<void> transfer(int recipientId, BuildContext context) async {
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      CommonToast.error("Enter a valid amount");
      return;
    }
    final res = await api.transfer(amount, recipientId);
    await handleAuthError(res, context);
    if (res.isSuccess) {
      CommonToast.success("Transfer successful");
      await AnalyticsService.logWalletTransaction('transfer_out', amount);
      await _updateBalance();
    } else {
      final msg = localizeError(res.code, res.error!);
      CommonToast.error(msg);
    }
    await loadTransactions();
    clearAmount();
    clearRecipient();
  }

  Future<ApiResult<Map<String, dynamic>>> verifyRecipientPhone(
      String phone, BuildContext context) async {
    _loading = true;
    notifyListeners();
    final res = await api.lookupRecipient(phone);
    await handleAuthError(res, context);
    if (res.isSuccess && res.data != null) {
      _recipientId = res.data!['id'] as int?;
      _recipientName = res.data!['name'] as String?;
    } else {
      _recipientId = null;
      _recipientName = null;
    }
    _loading = false;
    notifyListeners();
    return res;
  }

  void clearRecipient() {
    _recipientId = null;
    _recipientName = null;
  }

  Future<void> checkKycStatus() async {
    _loading = true;
    notifyListeners();
    final res = await KycApi().status(_userId);
    if (res.isSuccess && res.data != null) {
      _kycStatus = res.data!['status'] as String;
    }
    _loading = false;
    notifyListeners();
  }

  void onAmountChanged(String value) {
    final parsed = double.tryParse(value);
    _inputValid = parsed != null && parsed > 0;
    notifyListeners();
  }

  void clearAmount() {
    amountController.clear();
    upiController.clear();
    onAmountChanged('');
    clearRecipient();
  }

  void clearController() {
    amountController.clear();
    upiController.clear();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }
}

