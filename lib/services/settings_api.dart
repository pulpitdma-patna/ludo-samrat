import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class SettingsApi {
  final String baseUrl;
  SettingsApi({this.baseUrl = apiUrl});

  Future<Map<String, dynamic>> publicSettings() async {
    try {
      final resp = await http
          .get(Uri.parse("${baseUrl}/settings/public"))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return {};
        final data = jsonDecode(resp.body) as Map<String, dynamic>;

        // Ensure background image URLs are absolute.
        final uri = Uri.parse(baseUrl);
        for (final key in [
          'MOBILE_BACKGROUND_IMAGE_LIGHT',
          'MOBILE_BACKGROUND_IMAGE_DARK'
        ]) {
          final val = data[key];
          if (val is String && val.isNotEmpty) {
            final u = Uri.parse(val);
            if (!u.hasScheme && !val.startsWith('data:image')) {
              final path = val.startsWith('/')
                  ? val
                  : (uri.path.endsWith('/')
                      ? '${uri.path}$val'
                      : '${uri.path}/$val');
              data[key] = '${uri.scheme}://${uri.authority}$path';
            }
          }
        }

        return data;
      }
    } catch (_) {}
    return {};
  }
}

