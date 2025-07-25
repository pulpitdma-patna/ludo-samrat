import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_result.dart';
import '../common_widget/common_toast.dart';
import '../localized_errors.dart';
import '../widgets/kyc_modal.dart';

/// Handles authentication related errors.
/// If [result.code] is `401` or `403`, a logout is triggered.
Future<void> handleAuthError(ApiResult result, BuildContext ctx) async {
  if (!result.isSuccess && (result.code == '401' || result.code == '403')) {
    final msg = localizeError(result.code, result.error ?? 'Unauthorized');
    CommonToast.error(msg);
    if (result.code == '403' && result.error == 'KYC not completed') {
      await showKycModal(ctx);
    } else {
      await ctx.read<AuthProvider>().logout();
    }
  }
}
