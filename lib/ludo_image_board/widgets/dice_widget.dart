
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/ludo_image_board/constants.dart';
import 'package:frontend/ludo_image_board/ludo_provider.dart';
import 'package:provider/provider.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

class ImageDiceWidget extends StatelessWidget {
  final int gameId;
  final bool isThreeDices;
  const ImageDiceWidget({
    super.key,
    required this.gameId,
    this.isThreeDices = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LudoProvider>(
      builder: (context, value, child) {
        final List<int> diceValues = [1,value.diceResult,3]; // From API
        final int singleDiceValue = value.diceResult; // fallback

        if (isThreeDices) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                      // backgroundColor: Colors.blue, // customize if needed
                      // foregroundColor: Colors.white,
                    ),
                    onPressed: (){},
                    // onPressed: _rolling ? null : () => _sendRoll(currentTurn ?? 0),
                    child: Text(
                      true ? "P${171}\nRoll" :"Roll",
                      // currentTurn!= null ? "P${171}\nRoll" :"Roll",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final int diceVal = index < diceValues.length ? diceValues[index] : 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: value.throwDice,
                      child: value.diceStarted
                          ? Image.asset(
                        "assets/images/dice/draw.gif",
                        fit: BoxFit.contain,
                      )
                          : Image.asset(
                        "assets/images/dice/$diceVal.png",
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        } else {
          return RippleAnimation(
            color: value.gameState == LudoGameState.throwDice
                ? value.currentPlayer.color
                : Colors.white.withOpacity(0),
            ripplesCount: 3,
            minRadius: 8,
            maxRadius: 16,
            repeat: true,
            child: CupertinoButton(
              onPressed: value.throwDice,
              padding: EdgeInsets.zero,
              child: value.diceStarted
                  ? Image.asset(
                "assets/images/dice/draw.gif",
                fit: BoxFit.contain,
              )
                  : Image.asset(
                "assets/images/dice/$singleDiceValue.png",
                fit: BoxFit.contain,
              ),
            ),
          );
        }
      },
    );
  }

}

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:frontend/ludo_image_board/constants.dart';
// import 'package:frontend/ludo_image_board/ludo_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:simple_ripple_animation/simple_ripple_animation.dart';
//
// ///Widget for the dice
//
// class ImageDiceWidget extends ConsumerWidget {
//   final int gameId;
//
//   const ImageDiceWidget({super.key, required this.gameId});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final value = ref.watch(ludoStateNotifier(gameId));
//     final notifier = ref.read(ludoStateNotifier(gameId).notifier);
//
//     return RippleAnimation(
//       color: value.gameState == LudoGameState.throwDice
//           ? notifier.currentPlayer.color
//           : Colors.white.withOpacity(0),
//       ripplesCount: 3,
//       minRadius: 10,
//       maxRadius: 20.r,
//       repeat: true,
//       child: CupertinoButton(
//         onPressed: notifier.throwDice,
//         padding: const EdgeInsets.only(),
//         child: value.diceStarted
//             ? Image.asset("assets/images/dice/draw.gif", fit: BoxFit.contain)
//             : Image.asset("assets/images/dice/${value.diceResult}.png", fit: BoxFit.contain),
//       ),
//     );
//   }
// }
