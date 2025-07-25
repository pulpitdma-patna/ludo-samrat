import 'package:flutter/material.dart';
import 'package:frontend/services/app_preferences.dart';
import '../services/auth_api.dart';
import '../services/auth_storage.dart';
import '../services/api_result.dart';
import '../services/analytics_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _loading = false;
  bool _isAuthenticated = false;
  String? _token;

  bool get isLoading => _loading;
  bool get isAuthenticated =>_isAuthenticated;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _loading = true;
    _token = await AppPreferences().getToken();
    _isAuthenticated = _token != "" ? true : false;
    if (_isAuthenticated) {
      final res = await AuthApi().getMe(token: _token!);
      if (!res.isSuccess && (res.code == '401' || res.code == '403')) {
        await logout();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<ApiResult<String?>> sendOtp(String phone) async {
    _loading = true;
    notifyListeners();
    final result = await AuthApi().sendOtp(phone);
    _loading = false;
    notifyListeners();
    return result;
  }

  Future<ApiResult<String?>> signup(
      String phone, String password, String? fullName, String? referralCode) async {
    _loading = true;
    notifyListeners();
    final res = await AuthApi().signup(phone, password, fullName, referralCode);
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<ApiResult<void>> login(String phone, String code, {String? fcmToken}) async {
    _loading = true;
    notifyListeners();
    final res = await AuthApi().login(phone, code, fcmToken: fcmToken);
    _loading = false;
    if (res.isSuccess && res.data != null) {
      await AppPreferences().setToken(res.data!);
      await AppPreferences().setIsLoggedIn(true);
      _token = res.data!;
      _isAuthenticated = true;
      await AnalyticsService.logLogin();
    }
    notifyListeners();
    if (res.isSuccess) {
      return ApiResult.success();
    }
    return ApiResult.failure(res.error!, res.code);
  }

  Future<ApiResult<String?>> forgotPassword(String phone) async {
    _loading = true;
    notifyListeners();
    final res = await AuthApi().forgotPassword(phone);
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<ApiResult<void>> changePassword(
      String phone, String password, String code) async {
    _loading = true;
    notifyListeners();
    final res =
        await AuthApi().changePassword(phone, password, code: code);
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    try {
      await AuthApi().logout();
    } catch (_) {
      // ignore any logout errors
    }
    await AuthStorage.clear();
    await AppPreferences().clearPreferences();
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }


  Future<ApiResult<void>> loginWithNumberAndPassword(String phone,String password,{String? fcmToken}) async {
    _loading = true;
    notifyListeners();
    final res = await AuthApi().loginWithNumberAndPassword(phone,password,fcmToken:fcmToken);
    _loading = false;
    if (res.isSuccess && res.data != null) {
      await AppPreferences().setIsLoggedIn(true);
      await AppPreferences().setToken(res.data!);
      _isAuthenticated = true;
      // await AuthStorage.saveToken(res.data!);
      _token = res.data!;
      await AnalyticsService.logLogin();
    }
    notifyListeners();
    if (res.isSuccess) {
      return ApiResult.success();
    }
    return ApiResult.failure(res.error!, res.code);
  }

  Future<ApiResult<Map<String, dynamic>>> getMe({required String token}) async {
    _loading = true;
    notifyListeners();
    final res = await AuthApi().getMe(token: token);
    _loading = false;
    if (!res.isSuccess && (res.code == '401' || res.code == '403')) {
      await logout();
    }
    notifyListeners();
    return res;
  }






}
