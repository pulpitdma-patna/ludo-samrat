 import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static final AppPreferences _instance = AppPreferences._internal();
  static SharedPreferences? _preferences;


  static const String isLogin = "IsLogin";
  static const String token = "Token";
  static const String userId = "UserId";
  static const String phoneNumber = "PhoneNumber";


  factory AppPreferences() {
    return _instance;
  }

  AppPreferences._internal();

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }



  /// Set User Login
  Future<void> setIsLoggedIn(bool value) async {
    await _preferences?.setBool(isLogin, value);
  }

  bool getIsLoggedIn() {
    return _preferences?.getBool(isLogin) ?? false;
  }

  /// Set User Id
  Future<void> setUserId(int value) async {
    await _preferences?.setInt(userId, value);
  }

  Future<int> getUserId() async {
    return _preferences?.getInt(userId) ?? 0;
  }

  /// Set Login User Access Token
  Future<void> setToken(String value) async {
    await _preferences?.setString(token, value);
  }

   Future<String> getToken() async {
    return _preferences?.getString(token) ?? '';
  }

  /// Set User Id
  Future<void> setPhoneNumber(String value) async {
    await _preferences?.setString(phoneNumber, value);
  }

  Future<String> getPhoneNumber() async {
    return _preferences?.getString(phoneNumber) ?? '';
  }



  Future<void> clearPreferences() async {
    await _preferences?.clear();
  }
}
