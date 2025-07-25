import 'package:flutter/material.dart';
import '../services/settings_api.dart';
import '../main.dart';

class PublicSettingsProvider extends ChangeNotifier {
  final SettingsApi api;
  PublicSettingsProvider({SettingsApi? api}) : api = api ?? SettingsApi() {
    _load();
  }

  /// Reload settings from the backend.
  Future<void> refresh() => _load();

  bool aiPlayEnabled = true;
  String? _backgroundImageLight;
  String? _backgroundImageDark;

  String? get backgroundImageUrl {
    final mode = themeNotifier.value;
    if (mode == ThemeMode.dark) {
      return _backgroundImageDark ?? _backgroundImageLight;
    }
    return _backgroundImageLight;
  }

  Future<void> _load() async {
    final data = await api.publicSettings();
    final val = data['AI_PLAY_ENABLED'];
    if (val != null) {
      aiPlayEnabled = val == '1' || val == true || val == 'true';
      notifyListeners();
    }

    final lightBg = data['MOBILE_BACKGROUND_IMAGE_LIGHT'];
    if (lightBg is String && lightBg.isNotEmpty) {
      _backgroundImageLight = lightBg;
      notifyListeners();
    }
    final darkBg = data['MOBILE_BACKGROUND_IMAGE_DARK'];
    if (darkBg is String && darkBg.isNotEmpty) {
      _backgroundImageDark = darkBg;
      notifyListeners();
    }
  }

}

