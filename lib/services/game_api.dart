import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_result.dart';
import 'auth_storage.dart';

class GameApi {
  final String baseUrl;
  GameApi({this.baseUrl = apiUrl});



  Future<ApiResult<int?>> queueGame({int maxPlayers = 2, double joinFee = 0.0, bool ai = false}) async {
    try {
      final token = await AppPreferences().getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != "") {
        headers['Authorization'] = 'Bearer $token';
      } else if (!ai) {
        return ApiResult.failure('Not authenticated', '401');
      }
      final resp = await http
          .post(Uri.parse('$baseUrl/game/queue'),
              headers: headers,
              body: jsonEncode({
                'max_players': maxPlayers,
                'join_fee': joinFee,
                'ai': ai,
              }))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return ApiResult.success();
        final data = jsonDecode(resp.body);
        final tokenFromQueue = data['access_token'];
        if (tokenFromQueue is String && tokenFromQueue.isNotEmpty) {
          await AppPreferences().setToken(tokenFromQueue);
        }
        return ApiResult.success(data['game_id'] as int?);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<void>> leaveQueue() async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") {
        return ApiResult.failure('Not authenticated', '401');
      }
      final resp = await http
          .post(Uri.parse('$baseUrl/game/queue/leave'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return ApiResult.success();
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<void>> joinGame(int gameId, {String? color}) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") {
        return ApiResult.failure('Not authenticated', '401');
      }
      final resp = await http
          .post(Uri.parse('$baseUrl/game/$gameId/join'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({if (color != null) 'color': color}))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return ApiResult.success();
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<List<dynamic>>> recentGames() async {

    try {
      final token = await AppPreferences().getToken();
      final url = '$baseUrl/matches/';
      log("Recent Matches API = $url");
      final resp = await http
          .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        log("Recent Matches API Response = ${resp.body}");
        return ApiResult.success(jsonDecode(resp.body) as List<dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> createRoom({required int playerCount, required int stake}) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await http
          .post(Uri.parse('$baseUrl/quickplay/create'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "player_count": playerCount,
            "stake": stake
          }))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return ApiResult.success(
            jsonDecode(resp.body) as Map<String, dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> joinRoom(int room_id,
      {bool ai = false}) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await http
          .post(Uri.parse('$baseUrl/quickplay/$room_id/join'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "room_id": room_id,
            if (ai) "ai": true,
          }))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return ApiResult.success(
            jsonDecode(resp.body) as Map<String, dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> endRoom(
      int roomId, int matchId, int winnerId) async {
    try {
      debugPrint("Called Room End API");
      debugPrint("roomId =-= ${roomId}");
      debugPrint("matchId =-= ${matchId}");
      debugPrint("winnerId =-= ${winnerId}");
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');
      final resp = await http
          .post(Uri.parse('$baseUrl/quickplay/$roomId/end'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'winner_id': winnerId, 'match_id': matchId}));

      debugPrint("Room End API Response ${resp.body}");

          // .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return ApiResult.success(<String, dynamic>{});
        return ApiResult.success(
            jsonDecode(resp.body) as Map<String, dynamic>);
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
}
