import 'dart:convert';
import 'dart:developer';
import 'package:frontend/services/app_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'cache_service.dart';
import 'auth_storage.dart';
import 'api_result.dart';

class TournamentApi {
  final String baseUrl;
  TournamentApi({this.baseUrl = apiUrl});

  Future<List<dynamic>> activeTournament() async {
    try {
      final token = await AppPreferences().getToken();
      final url = '$baseUrl/tournament/active';
      log("Active Tournament API = $url");
      if (token == "") return [];
      final resp = await http.get(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        log("Active Tournament API Response = ${resp.body}");
        await CacheService.set('tournaments', resp.body);
        return jsonDecode(resp.body) as List<dynamic>;
      }
    } catch (_) {}
    final cached = await CacheService.get('tournaments');
    if (cached != null) {
      return jsonDecode(cached) as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> allTournament({
    double? minFee,
    double? maxFee,
    String? category,
  }) async {
    try {
      final token = await AppPreferences().getToken();

      final params = <String, String>{};
      if (minFee != null) params['min_fee'] = minFee.toString();
      if (maxFee != null) params['max_fee'] = maxFee.toString();
      if (category != null && category.isNotEmpty) {
        params['category'] = category;
      }

      var uri = Uri.parse('$baseUrl/tournament');
      uri = uri.replace(queryParameters: params.isEmpty ? null : params);

      log("All Tournament API = $uri");
      if (token == "") return [];
      final resp = await http.get(uri,
          headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        log("All Tournament API Response = ${resp.body}");
        await CacheService.set('all-tournaments', resp.body);
        return jsonDecode(resp.body) as List<dynamic>;
      }
    } catch (_) {}
    final cached = await CacheService.get('all-tournaments');
    if (cached != null) {
      return jsonDecode(cached) as List<dynamic>;
    }
    return [];
  }

  Future<ApiResult<Map<String, dynamic>>> join(int id) async {
    final token = await AppPreferences().getToken();
    final url = '$baseUrl/tournament/$id/book';
    log('Join Tournament API = $url');
    if (token == '') return ApiResult.failure('Not authenticated', '401');
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({}),
      );
      log('Join Tournament Status Code: ${resp.statusCode}');
      log('Join Tournament Response Body: ${resp.body}');
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        Map<String, dynamic> data = {};
        if (resp.body.isNotEmpty) {
          try {
            data = jsonDecode(resp.body) as Map<String, dynamic>;
          } catch (_) {
            // ignore malformed json
          }
        }
        return ApiResult.success(data);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (e) {
      log('Error joining tournament: $e');
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    final token = await AppPreferences().getToken();
    if (token == "") return;
    await http.post(Uri.parse('$baseUrl/tournament/create-simple'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data));
  }

  Future<List<dynamic>> leaderboard(int id) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return [];
      final resp = await http.get(
        Uri.parse('$baseUrl/tournament/$id/leaderboard'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> tournament(int id) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return null;
      final resp = await http.get(
        Uri.parse('$baseUrl/tournament/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// New wrapper for getting tournament details
  Future<Map<String, dynamic>?> getTournament(int id) async {
    return tournament(id);
  }

  Future<List<dynamic>> participants(int id) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return [];
      final resp = await http.get(
        Uri.parse('$baseUrl/tournament/$id/participants'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch participants using the new endpoint
  Future<List<dynamic>> getParticipants(int id) async {
    return participants(id);
  }

  /// Retrieve bracket information for a tournament
  Future<Map<String, dynamic>?> getBracket(int id) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return null;
      final resp = await http.get(
        Uri.parse('$baseUrl/tournament/$id/bracket'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String,dynamic>?> getMyStats() async {
    try {
      final token = await AppPreferences().getToken();
      final url = '$baseUrl/tournament/my-stats';
      log("My Stats API = $url");
      if (token == "") return null;
      final resp = await http.get(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        log("My Stats API Response = ${resp.body}");
        final jsonMap = jsonDecode(resp.body);
        return jsonMap ;
      }
    } catch (_) {
      return null;
    }
    return null;
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
}

