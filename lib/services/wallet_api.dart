import 'dart:convert';
import 'dart:developer';
import 'package:frontend/services/app_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_result.dart';
import 'cache_service.dart';
import 'auth_storage.dart';

class WalletApi {
  final String baseUrl;
  WalletApi({this.baseUrl = apiUrl});

  Future<ApiResult<double>> balance({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await httpClient
          .get(Uri.parse('$baseUrl/wallet/balance'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return ApiResult.success(0.0);
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final bal = data['balance'] ?? data['amount'] ?? 0;
        double parsed;
        if (bal is String) {
          parsed = double.tryParse(bal) ?? 0.0;
        } else if (bal is num) {
          parsed = bal.toDouble();
        } else {
          parsed = 0.0;
        }
        return ApiResult.success(parsed);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<ApiResult<Map<String, dynamic>>> deposit(double amount, int methodId,
      {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final token = await AppPreferences().getToken();
      final url = '$baseUrl/wallet/deposit';
      log("Add Money API $url");
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await httpClient
          .post(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'amount': amount,
                'payment_method_id': methodId,
              }))
          .timeout(const Duration(seconds: 5));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (resp.body.isNotEmpty) {
            try {
              final jsonMap = jsonDecode(resp.body);
              if (jsonMap is Map<String, dynamic>) {
                log("Add Money API Response ${jsonEncode(jsonMap)}");
                return ApiResult.success(jsonMap);
              }
            } catch (_) {
              // ignore invalid JSON and fall through to return empty map
            }
          }
          return ApiResult.success(<String, dynamic>{});
        }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<ApiResult<List<dynamic>>> paymentMethods() async {
    final httpClient = http.Client();
    try {
      final resp = await httpClient
          .get(Uri.parse('$baseUrl/payment-methods/active'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isNotEmpty) {
          final data = jsonDecode(resp.body) as List<dynamic>;
          return ApiResult.success(data);
        }
        return ApiResult.success(<dynamic>[]);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    } finally {
      httpClient.close();
    }
  }

  Future<ApiResult<void>> withdraw(double amount, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await httpClient
          .post(Uri.parse('$baseUrl/wallet/withdraw'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'amount': amount}))
          .timeout(const Duration(seconds: 5));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (resp.body.isNotEmpty) {
            try {
              jsonDecode(resp.body);
            } catch (_) {
              // ignore malformed json
            }
          }
          return ApiResult.success();
        }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<ApiResult<void>> transfer(double amount, int recipientId,
      {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await httpClient
          .post(Uri.parse('$baseUrl/wallet/transfer'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'recipient_id': recipientId,
                'amount': amount,
              }))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isNotEmpty) {
          try {
            jsonDecode(resp.body);
          } catch (_) {}
        }
        return ApiResult.success();
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<ApiResult<Map<String, dynamic>>> lookupRecipient(String phone) async {
    final httpClient = http.Client();
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await httpClient
          .get(Uri.parse('$baseUrl/wallet/recipient?phone=$phone'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isNotEmpty) {
          final data = jsonDecode(resp.body);
          if (data is Map<String, dynamic>) {
            return ApiResult.success(data);
          }
        }
        return ApiResult.success(<String, dynamic>{});
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    } finally {
      httpClient.close();
    }
  }

  Map<String, String> _parseError(http.Response resp) {
    if (resp.body.isNotEmpty) {
      try {
        final data = jsonDecode(resp.body);
        final message = data['detail'] ?? data['message'] ?? 'Request failed';
        return {'message': message, 'code': '${resp.statusCode}'};
      } catch (_) {
        // fall through to generic error
      }
    }
    return {'message': 'Request failed', 'code': '${resp.statusCode}'};
  }

  Future<List<dynamic>> transactions() async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return [];
      final resp = await http.get(
        Uri.parse('$baseUrl/wallet/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        await CacheService.set('wallet_transactions', resp.body);
        return jsonDecode(resp.body) as List<dynamic>;
      }
    } catch (_) {}
    final cached = await CacheService.get('wallet_transactions');
    if (cached != null) {
      return jsonDecode(cached) as List<dynamic>;
    }
    return [];
  }
}

