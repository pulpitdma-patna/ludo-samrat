import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameStateStorage {
  static const _key = 'saved_game_state';

  static Future<void> save(int gameId, Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({'game_id': gameId, 'state': state});
    await prefs.setString(_key, data);
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
