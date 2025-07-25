import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/widgets/enhanced_ludo_board_widget.dart';
import 'package:frontend/widgets/enhanced_token_widget.dart';
import 'package:frontend/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders radial gradient background and supports scaling',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final provider = SettingsProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: EnhancedLudoBoardWidget(
              positions: {0: [0]},
              playerColors: {0: Colors.red},
              playerCorners: {0: 3},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.gradient, isA<RadialGradient>());

    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.minScale, 0.5);
    expect(viewer.maxScale, 3.0);
  });

  testWidgets('negative index positions token in home square', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final provider = SettingsProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: EnhancedLudoBoardWidget(
              positions: {0: [-1]},
              playerColors: {0: Colors.red},
              playerCorners: {0: 3},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final tokenWidget =
        tester.widget<EnhancedTokenWidget>(find.byType(EnhancedTokenWidget));

    final boardSize = 225.0;
    const columns = 15;
    final cell = boardSize / columns;
    final rows = (boardSize / columns).ceil();
    final zone = Rect.fromLTWH(
      cell * (columns - 6),
      cell * (rows - 6),
      cell * 6,
      cell * 6,
    );
    final zoneCellWidth = zone.width / 2;
    final zoneCellHeight = zone.height / 2;
    final expectedDx =
        zone.left + (zoneCellWidth - provider.tokenSize) / 2;
    final expectedDy =
        zone.top + (zoneCellHeight - provider.tokenSize) / 2;

    expect(tokenWidget.position.dx, closeTo(expectedDx, 0.01));
    expect(tokenWidget.position.dy, closeTo(expectedDy, 0.01));
  });

  testWidgets('token animation from home starts at home offset', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final provider = SettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: EnhancedLudoBoardWidget(
              positions: const {0: [-1]},
              playerColors: const {0: Colors.red},
              playerCorners: const {0: 3},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final boardSize = 225.0;
    const columns = 15;
    final cell = boardSize / columns;
    final rows = (boardSize / columns).ceil();
    final zone = Rect.fromLTWH(
      cell * (columns - 6),
      cell * (rows - 6),
      cell * 6,
      cell * 6,
    );
    final zoneCellWidth = zone.width / 2;
    final zoneCellHeight = zone.height / 2;
    final expectedDx = zone.left + (zoneCellWidth - provider.tokenSize) / 2;
    final expectedDy = zone.top + (zoneCellHeight - provider.tokenSize) / 2;

    // update positions to move token to start cell
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: EnhancedLudoBoardWidget(
              positions: const {0: [0]},
              playerColors: const {0: Colors.red},
              playerCorners: const {0: 3},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final movingToken =
        tester.widget<EnhancedTokenWidget>(find.byType(EnhancedTokenWidget));
    expect(movingToken.position.dx, closeTo(expectedDx, 0.01));
    expect(movingToken.position.dy, closeTo(expectedDy, 0.01));

    await tester.pumpAndSettle();
  });
}
