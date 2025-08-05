import 'dart:developer' as developer;
const String apiUrl =
String.fromEnvironment('API_URL', defaultValue: 'https://ludosamrat.com/api');
/// WebSocket URL for real-time game communication

Uri get webSocketUri {
  var uri = Uri.parse(apiUrl);

  if (uri.scheme == 'http') {
    developer.log(
      'API_URL "$apiUrl" uses http://; upgrading to https://.',
      level: 1000,
      name: 'config',
    );
    uri = uri.replace(scheme: 'https');
  }

  // Ensure path has no trailing slash
  final basePath = uri.path.replaceAll(RegExp(r'/+$'), '');
  final fullPath = '$basePath/game/ws';

  return uri.replace(scheme: 'wss', path: fullPath);
}

// Uri get webSocketUri {
//   var uri = Uri.parse(apiUrl);
//   if (uri.scheme == 'http') {
//     developer.log(
//       'API_URL "\$apiUrl" uses http://; upgrading to https://.',
//       level: 1000,
//       name: 'config',
//     );
//     uri = uri.replace(scheme: 'https');
//   }
//   final path = uri.path.endsWith('/')
//       ? '${uri.path}game/ws/'
//       : '${uri.path}/game/ws/';
//   return uri.replace(scheme: 'wss', path: path);
// }
/// Convenience getter for the WebSocket URL as a string.
String get socketBaseUrl => webSocketUri.toString();
/// Razorpay key for processing payments.
///
/// Set using ⁠ --dart-define=RAZORPAY_KEY=<key> ⁠ when running the app or
/// by adding ⁠ RAZORPAY_KEY ⁠ to ⁠ .env ⁠.
const String razorpayKey =
String.fromEnvironment('RAZORPAY_KEY', defaultValue: '');
