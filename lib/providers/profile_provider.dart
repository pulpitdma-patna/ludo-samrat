import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/services/profile_api.dart';
import 'package:image_picker/image_picker.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileApi api;

  ProfileProvider({ProfileApi? api}) : api = api ?? ProfileApi() {
    _initFcmToken(); // Call async initializer
  }

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  String _authToken = "";
  String get authToken => _authToken;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _avatarUrl;
  String? get avatarUrl => _avatarUrl;

  String _name = "Guest";
  String? get name => _name;

  String _phoneNumber = "";
  String? get phoneNumber => _phoneNumber;

  Future<void> _initFcmToken() async {
    _fcmToken = await FirebaseMessaging.instance.getToken();
    _authToken = await AppPreferences().getToken();
    notifyListeners();
  }

  Future<void> getProfile() async {
    _loading = true;
    notifyListeners();
    final result = await api.getProfile();
    _loading = false;
    if (result.isSuccess) {
      _avatarUrl = result.data?['avatar_url'] as String?;
    }
    notifyListeners();
  }

  Future<void> getMe() async {
    _loading = true;
    notifyListeners();
    final result = await api.getMe(token: _authToken);
    _loading = false;
    if (result.isSuccess) {
      _avatarUrl = result.data?['avatar_url'] as String? ?? _avatarUrl;
      _name = "${result.data?['name']??'-'}";
      _phoneNumber = "${result.data?['phone_number']??'-'}";
    }
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? password, XFile? avatar}) async {
    _loading = true;
    notifyListeners();
    final result = await api.updateProfile(
      name: name,
      password: password,
      avatar: avatar,
    );
    _loading = false;
    if (result.isSuccess) {
      _avatarUrl = result.data?['avatar_url'] as String? ?? _avatarUrl;
      if (result.data?['name'] != null) {
        _name = result.data?['name'];
      }
    }
    notifyListeners();
    return result.isSuccess;
  }
}
