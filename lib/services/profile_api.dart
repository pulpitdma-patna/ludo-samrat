import 'dart:convert';
import 'package:frontend/services/app_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_result.dart';

class ProfileApi {
  final String baseUrl;
  ProfileApi({this.baseUrl = apiUrl});

  Future<ApiResult<Map<String, dynamic>>> getProfile() async {
    try {
      final token = await AppPreferences().getToken();
      final resp = await http
          .get(Uri.parse('$baseUrl/profile'),
        headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final jsonMap = jsonDecode(resp.body);
        AppPreferences().setUserId(jsonMap['id']??0);
        AppPreferences().setPhoneNumber(jsonMap['phone_number']??'');
        return ApiResult.success(
            jsonDecode(resp.body) as Map<String, dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> setAvatar(String url) async {
    try {
      final resp = await http
          .patch(
            Uri.parse('$baseUrl/profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'avatar_url': url}),
          )
          .timeout(const Duration(seconds: 5));
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

  Future<ApiResult<Map<String, dynamic>>> updateProfile({
    String? name,
    String? password,
    XFile? avatar,
  }) async {
    try {
      final token = await AppPreferences().getToken();
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/profile'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      if (name != null) request.fields['name'] = name;
      if (password != null) request.fields['password'] = password;
      if (avatar != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', avatar.path),
        );
      }
      final streamed = await request.send().timeout(const Duration(seconds: 5));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200 && body.isNotEmpty) {
        return ApiResult.success(jsonDecode(body) as Map<String, dynamic>);
      }
      final err = _parseError(http.Response(body, streamed.statusCode));
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<List<dynamic>>> listFriends() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/friends'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        return ApiResult.success(jsonDecode(resp.body) as List<dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<void>> addFriend(int id) async {
    try {
      final resp = await http
          .post(Uri.parse('$baseUrl/friends'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'friend_id': id}))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return ApiResult.success();
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<void>> removeFriend(int id) async {
    try {
      final resp = await http
          .delete(Uri.parse('$baseUrl/friends/$id'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return ApiResult.success();
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<List<dynamic>>> matchHistory() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/matches'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        return ApiResult.success(jsonDecode(resp.body) as List<dynamic>);
      }
      final err = _parseError(resp);
      return ApiResult.failure(err['message']!, err['code']);
    } catch (_) {
      return ApiResult.failure('Network error', 'network_error');
    }
  }

  Future<ApiResult<Map<String,dynamic>>> getMe({required String token}) async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
      );
      if (resp.statusCode == 200) {
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
