import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/screens/board_widget.dart';
import 'package:frontend/providers/settings_provider.dart';

void main() {
  testWidgets('token semantics preserved in color blind mode', (tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final provider = SettingsProvider();
    await provider.setColorBlindMode(true);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              positions: {0: [0]},
              playerColors: {0: Colors.red},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Player 0 token 1'), findsOneWidget);
  });
}
