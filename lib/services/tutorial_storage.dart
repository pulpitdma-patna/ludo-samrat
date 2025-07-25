import 'package:shared_preferences/shared_preferences.dart';

class TutorialStorage {
  static const _prefix = 'tutorial_';

  static Future<bool> hasSeenTutorial() => hasSeenFeature('basic');

  static Future<void> setSeen() => setFeatureSeen('basic');

  static Future<bool> hasSeenFeature(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$feature') ?? false;
  }

  static Future<void> setFeatureSeen(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$feature', true);
  }
}
