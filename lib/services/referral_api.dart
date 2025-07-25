import 'dart:convert';
import 'package:frontend/services/app_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_result.dart';
import 'cache_service.dart';
import 'auth_storage.dart';

class ReferralApi {
  final String baseUrl;
  ReferralApi({this.baseUrl = apiUrl});




  Future<ApiResult<Map<String,dynamic>>> getEarnings({required String token}) async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/referral/earnings/2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return ApiResult.success(jsonDecode(resp.body) as Map<String, dynamic>);
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

