import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/wallet_api.dart';
import 'package:frontend/services/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WalletApi', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'Token': 't'});
      await AppPreferences.init();
    });

    test('deposit handles empty body without throwing', () async {
      final api = WalletApi(baseUrl: 'http://example.com');
      final client = MockClient((request) async => http.Response('', 200));
      final res = await api.deposit(10, 1, client: client);
      expect(res.isSuccess, true);
      expect(res.data, isA<Map<String, dynamic>>());
    });

    test('withdraw handles empty body without throwing', () async {
      final api = WalletApi(baseUrl: 'http://example.com');
      final client = MockClient((request) async => http.Response('', 200));
      final res = await api.withdraw(10, client: client);
      expect(res.isSuccess, true);
    });

    test('balance parses double value', () async {
      final api = WalletApi(baseUrl: 'http://example.com');
      final client = MockClient(
          (request) async => http.Response('{"balance": 5.0}', 200));
      final res = await api.balance(client: client);
      expect(res.isSuccess, true);
      expect(res.data, 5.0);
    });
  });
}
