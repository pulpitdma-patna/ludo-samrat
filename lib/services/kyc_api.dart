import 'dart:convert';
import 'package:frontend/services/app_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_result.dart';
import 'auth_storage.dart';
import 'package:image_picker/image_picker.dart';

class KycApi {
  final String baseUrl;
  KycApi({this.baseUrl = apiUrl});

  Future<ApiResult<Map<String, dynamic>>> submitFile(XFile file) async {
    final token = await AppPreferences().getToken();
    if (token == "") return ApiResult.failure('Not authenticated', '401');
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/kyc/submit'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('document', file.path));
      final streamed =
          await request.send().timeout(const Duration(seconds: 5));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        return ApiResult.success(
            jsonDecode(body) as Map<String, dynamic>);
      }
      final err = _parseError(http.Response(body, streamed.statusCode));
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> status(int userId) async {
    final token = await AppPreferences().getToken();
    if (token == "") return ApiResult.failure('Not authenticated', '401');
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/kyc/status?user_id=$userId'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        return ApiResult.success(
            jsonDecode(resp.body) as Map<String, dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> approve(int userId) async {
    final token = await AppPreferences().getToken();
    if (token == "") return ApiResult.failure('Not authenticated', '401');
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/kyc/approve/$userId'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
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

  Future<ApiResult<Map<String, dynamic>>> reject(int userId) async {
    final token = await AppPreferences().getToken();
    if (token == "") return ApiResult.failure('Not authenticated', '401');
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/kyc/reject/$userId'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
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

  Future<ApiResult<List<dynamic>>> pending() async {
    final token = await AppPreferences().getToken();
    if (token == "") return ApiResult.failure('Not authenticated', '401');
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/kyc/pending'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
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
