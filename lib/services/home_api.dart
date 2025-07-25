import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config.dart';

class HomeApi {
  final String baseUrl;
  HomeApi({this.baseUrl = apiUrl});

  Future<List<dynamic>> getBanner() async {
    try {
      final url = '$baseUrl/banners/public';
      log("Banner API = $url");
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        log("Banner API Response = ${resp.body}");
        return jsonDecode(resp.body) as List<dynamic>;
      } else {
        log("Banner API Error: ${resp.statusCode} - ${resp.body}");
      }
    } catch (e) {
      log("Banner API Exception: $e");
    }
    return [];
  }


}

