import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/widgets/enhanced_token_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('token moves along provided path', (tester) async {
    final key = GlobalKey<EnhancedTokenWidgetState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(children: [
          EnhancedTokenWidget(
            key: key,
            position: Offset.zero,
            size: 20,
            asset: 'assets/tokens/token_red.svg',
            playerId: 0,
            color: Colors.red,
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(key)), Offset.zero);

    await key.currentState!.moveAlongPath([
      Offset.zero,
      const Offset(50, 50),
    ]);

    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getTopLeft(find.byKey(key));
    expect(mid.dx, greaterThan(0));
    expect(mid.dy, greaterThan(0));
    expect(mid.dx, lessThan(50));
    expect(mid.dy, lessThan(50));

    await tester.pumpAndSettle();

    final end = tester.getTopLeft(find.byKey(key));
    expect(end.dx, closeTo(50, 0.1));
    expect(end.dy, closeTo(50, 0.1));
  });
}
