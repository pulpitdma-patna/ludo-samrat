import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/screens/board_painter.dart';

class FailingAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.error(Exception('missing'));

  @override
  Future<ByteData> load(String key) =>
      Future.error(Exception('missing'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loadStarSvgs generates fallback when assets missing', (tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FailingAssetBundle(),
        child: const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
      ),
    );

    await BoardPainter.loadStarSvgs(tester.element(find.byType(SizedBox)));
    for (var i = 0; i < 4; i++) {
      expect(BoardPainter.starPic(i), isNotNull);
    }
  });

  test('loadWoodImage generates fallback when asset missing', () async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async => null);
    await BoardPainter.loadWoodImage();
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
    expect(BoardPainter.woodShader, isNotNull);
  });
}
