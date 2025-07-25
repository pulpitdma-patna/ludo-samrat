const String apiUrl =
String.fromEnvironment('API_URL', defaultValue: 'https://ludosamrat.com/api');

/// Razorpay key for processing payments.
///
/// Set using `--dart-define=RAZORPAY_KEY=<key>` when running the app or
/// by adding `RAZORPAY_KEY` to `.env`.
const String razorpayKey =
String.fromEnvironment('RAZORPAY_KEY', defaultValue: '');
