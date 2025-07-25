import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/widgets/dice_widget.dart';

void main() {
  testWidgets('shows casino icon when values are null', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DiceWidget()),
    ));

    expect(find.byIcon(Icons.casino_outlined), findsOneWidget);
  });

  testWidgets('shows casino icon when values are empty even if rolling', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DiceWidget(rolling: true, values: [])),
    ));

    expect(find.byIcon(Icons.casino_outlined), findsOneWidget);
  });

  testWidgets('shows dice image for single value', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DiceWidget(values: [3])),
    ));
    await tester.pumpAndSettle();

    final svgFinder = find.byType(SvgPicture);
    expect(svgFinder, findsOneWidget);
    final SvgPicture pic = tester.widget(svgFinder);
    final loader = pic.bytesLoader as SvgAssetLoader;
    expect(loader.assetName, 'assets/images/dice3d_3.svg');
    expect(find.text('3'), findsNothing);
  });

  testWidgets('shows dice images for multiple values', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DiceWidget(values: [1, 2, 3])),
    ));
    await tester.pumpAndSettle();

    final svgFinder = find.byType(SvgPicture);
    expect(svgFinder, findsNWidgets(3));
    final widgets = tester.widgetList(svgFinder).toList();
    expect((widgets[0] as SvgPicture).bytesLoader,
        isA<SvgAssetLoader>()
            .having((p) => (p as SvgAssetLoader).assetName, 'assetName',
                'assets/images/dice3d_1.svg'));
    expect((widgets[1] as SvgPicture).bytesLoader,
        isA<SvgAssetLoader>()
            .having((p) => (p as SvgAssetLoader).assetName, 'assetName',
                'assets/images/dice3d_2.svg'));
    expect((widgets[2] as SvgPicture).bytesLoader,
        isA<SvgAssetLoader>()
            .having((p) => (p as SvgAssetLoader).assetName, 'assetName',
                'assets/images/dice3d_3.svg'));
  });

  testWidgets('taps select die and highlights selection', (tester) async {
    int? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => DiceWidget(
            values: const [1, 2],
            selected: selected,
            onSelected: (d) => setState(() => selected = d),
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNWidgets(2));

    await tester.tap(find.byType(GestureDetector).at(1));
    await tester.pump();

    expect(selected, 2);
  });
}
