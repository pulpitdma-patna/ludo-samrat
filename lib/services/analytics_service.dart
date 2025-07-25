import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Future<void> logLogin() async {
    await analytics.logLogin(loginMethod: 'otp');
  }

  static Future<void> logTournamentJoin(int id) async {
    await analytics.logEvent(name: 'tournament_join', parameters: {'id': id});
  }

  static Future<void> logWalletTransaction(String type, double amount) async {
    await analytics.logEvent(
      name: 'wallet_transaction',
      parameters: {'type': type, 'amount': amount},
    );
  }

  static Future<void> logGameStart(int gameId) async {
    await analytics.logEvent(name: 'game_start', parameters: {'game_id': gameId});
  }

  static Future<void> logGameEnd(int gameId) async {
    await analytics.logEvent(name: 'game_end', parameters: {'game_id': gameId});
  }

  static Future<void> logMatchWin(int gameId, int winnerId) async {
    await analytics.logEvent(
      name: 'match_win',
      parameters: {'game_id': gameId, 'winner_id': winnerId},
    );
  }
}
