import 'dart:convert';
import 'dart:developer';
import 'package:frontend/services/app_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_storage.dart';
import 'api_result.dart';

class AuthApi {
  final String baseUrl;
  AuthApi({this.baseUrl = apiUrl});

  /// Returns the OTP code when [SHOW_OTP] is enabled on the backend.
  Future<ApiResult<String?>> signup(String phone, String password,
      String? fullName, String? referralCode) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone_number': phone,
            'password': password,
            if (fullName != null) 'full_name': fullName,
            if (referralCode != null) 'referral_code': referralCode,
          }))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return ApiResult.success(data['otp'] as String?);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  /// Request an OTP for an existing account. Returns the OTP code when
  /// [SHOW_OTP] is enabled on the backend.
  Future<ApiResult<String?>> sendOtp(String phone) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone_number': phone}))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return ApiResult.success(data['otp'] as String?);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<String>> login(String phone, String code,
      {String? fcmToken}) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone_number': phone,
            'code': code,
            if (fcmToken != null) 'fcm_token': fcmToken,
          }))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return ApiResult.success(data['access_token'] as String?);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  /// Request an OTP to reset the password for the given phone number.
  /// Returns the OTP code when SHOW_OTP is enabled on the backend.
  Future<ApiResult<String?>> forgotPassword(String phone) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone_number': phone}))
          .timeout(const Duration(seconds: 5));
      log('Forgot password response: ${resp.body}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return ApiResult.success(data['otp'] as String?);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (e, stacktrace) {
      log('ForgotPassword Exception: $e');
      log('Stacktrace: $stacktrace');
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  /// Change the account password using either an OTP or the old password.
  Future<ApiResult<void>> changePassword(String phone, String newPassword,
      {String? code, String? oldPassword}) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/auth/change-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone_number': phone,
            'new_password': newPassword,
            if (code != null) 'code': code,
            if (oldPassword != null) 'old_password': oldPassword,
          }))
          .timeout(const Duration(seconds: 5));
        log('Change password response: ${resp.body}');
      if (resp.statusCode == 200) {
        return ApiResult.success();
      }
      final err = _parseError(resp);
      log('Change password error: $err');
      return ApiResult.failure(err['message']!, err['code']);
    } catch (e, stacktrace) {
      log('ChangePassword Exception: $e');
      log('Stacktrace: $stacktrace');
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<void>> logout() async {
    final token = await AppPreferences().getToken();
    if (token == "") return ApiResult.success();
    try {
      final resp = await http.post(Uri.parse('$baseUrl/auth/logout'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return ApiResult.success();
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Map<String, String> _parseError(http.Response resp) {
    try {
      final data = jsonDecode(resp.body);
      final message = data['detail'] ?? data['message'] ?? 'Request failed';
      return {'message': message, 'code': '${resp.statusCode}'};
    } catch (_) {
      return {'message': 'Request failed', 'code': '${resp.statusCode}'};
    }
  }

  Future<ApiResult<String>> loginWithNumberAndPassword(String phone, String password,{String? fcmToken}) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/auth/login/password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone_number': phone,
            'password': password,
            if (fcmToken != null) 'fcm_token': fcmToken,
          }))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return ApiResult.success(data['access_token'] as String?);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getMe({required String token}) async {
    try {

      final resp = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        return ApiResult.success(
            jsonDecode(resp.body) as Map<String, dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

}
