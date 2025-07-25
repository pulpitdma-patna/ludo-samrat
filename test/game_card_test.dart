import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/widgets/game_card.dart';

void main() {
  testWidgets('renders header and body semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameCard(
            title: Text('Test Tournament'),
            entryFee: 5,
            prize: 50,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('card header'), findsOneWidget);
    expect(find.bySemanticsLabel('card body'), findsOneWidget);
    expect(find.bySemanticsLabel('card footer'), findsNothing);
  });

  testWidgets('button semantics and start time text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameCard(
            title: Text('Test'),
            entryFee: 5,
            prize: 50,
            startTime: 'Jan 1, 10:00 AM',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('game card action'), findsOneWidget);
    expect(find.text('Jan 1, 10:00 AM'), findsOneWidget);
  });
}
