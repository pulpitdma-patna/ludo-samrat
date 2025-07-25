import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  final String baseUrl;
  ApiService({this.baseUrl = apiUrl});

  static List<dynamic> decode(String body) => jsonDecode(body) as List<dynamic>;

  Future<http.Response> signup(String phone, String password) {
    return http.post(Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone, 'password': password}));
  }

  Future<http.Response> login(String phone, String password) {
    return http.post(Uri.parse('$baseUrl/auth/login/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone, 'password': password}));
  }

  Future<http.Response> getTournaments() {
    return http.get(Uri.parse('$baseUrl/tournament/active'));
  }

  Future<http.Response> createTournament(Map<String, dynamic> data) {
    return http.post(Uri.parse('$baseUrl/tournament/create'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
  }

  Future<http.Response> walletDeposit(int amount) {
    return http.post(Uri.parse('$baseUrl/wallet/deposit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}));
  }

  Future<http.Response> walletWithdraw(int amount) {
    return http.post(Uri.parse('$baseUrl/wallet/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}));
  }
}
