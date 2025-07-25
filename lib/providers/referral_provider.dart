import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/services/referral_api.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralApi api;

  ReferralProvider({ReferralApi? api}) : api = api ?? ReferralApi() {
    _initFcmToken(); // Call async initializer
  }

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  String _authToken = "";
  String get authToken => _authToken;

  bool _loading = false;
  bool get isLoading => _loading;

  String _invitedFriends = "0";
  String? get invitedFriends => _invitedFriends;

  String _totalEarning = "0";
  String? get totalEarning => _totalEarning;

  Future<void> _initFcmToken() async {
    _fcmToken = await FirebaseMessaging.instance.getToken();
    _authToken = await AppPreferences().getToken();
    notifyListeners();
  }

  Future<void> getEarnings() async {
    _loading = true;
    notifyListeners();
    if (_authToken.isEmpty) {
      await _initFcmToken();
    }
    final result = await api.getEarnings(token: _authToken);
    if(result.data != null){
      _totalEarning = "${result.data!['earnings']}";
    }
    _loading = false;
    notifyListeners();
  }

}
