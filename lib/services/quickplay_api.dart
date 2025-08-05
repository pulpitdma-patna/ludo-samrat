import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_result.dart';
import 'game_api.dart';

class QuickPlayApi extends GameApi {
  QuickPlayApi({super.baseUrl});

  Future<ApiResult<List<dynamic>>> listRooms({
    String? q,
    double? minStake,
    double? maxStake,
  }) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');

      final params = <String, String>{};
      if (q != null && q.isNotEmpty) params['q'] = q;
      if (minStake != null) params['min_stake'] = minStake.toString();
      if (maxStake != null) params['max_stake'] = maxStake.toString();

      var uri = Uri.parse('$baseUrl/quickplay/');
      uri = uri.replace(queryParameters: params.isEmpty ? null : params);

      debugPrint("QuickPlay API $uri");
      debugPrint("Token $token");

      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return ApiResult.success(<dynamic>[]);
        var jsonBody = jsonDecode(resp.body);
        List data = [];
        if(jsonBody is Map && jsonBody['items'] != null && jsonBody['items'] is List ){
          data = jsonBody['items'];
        }else if(jsonBody is List){
          data = jsonBody;
        }
        return ApiResult.success(data);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<List<dynamic>>> participants(int roomId) async {
    try {
      final token = await AppPreferences().getToken();
      if (token == "") return ApiResult.failure('Not authenticated', '401');

      final resp = await http
          .get(Uri.parse('$baseUrl/quickplay/$roomId/participants'),
              headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return ApiResult.success(<dynamic>[]);
        return ApiResult.success(jsonDecode(resp.body) as List<dynamic>);
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
