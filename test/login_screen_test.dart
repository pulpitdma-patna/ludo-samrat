import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/otp_verification_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_result.dart';

class FakeAuthProvider extends AuthProvider {
  @override
  Future<ApiResult<String?>> sendOtp(String phone) async {
    return ApiResult.success();
  }
}

void main() {
  testWidgets('navigates to OTP screen after tapping Login Now', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => LoginScreen()),
      GoRoute(
        path: '/verify/:phone',
        builder: (context, state) =>
            OtpVerificationScreen(phoneNumber: state.pathParameters['phone']!),
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FakeAuthProvider(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '1234567890');
    await tester.tap(find.text('Login Now'));
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsOneWidget);
  });
}
