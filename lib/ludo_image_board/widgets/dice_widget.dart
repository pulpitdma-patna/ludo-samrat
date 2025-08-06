
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/ludo_image_board/constants.dart';
import 'package:frontend/ludo_image_board/ludo_provider.dart';
import 'package:frontend/ludo_image_board/ludo_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';


class ImageDiceWidget extends ConsumerStatefulWidget {
  final int gameId;
  final bool isThreeDices;
  final bool isRolling;
  final void Function(int playerId)? onRoll;
  final void Function(int playerId, int tokenIndex)? onTokenTap;

  const ImageDiceWidget({
    super.key,
    required this.gameId,
    this.isThreeDices = false,
    this.isRolling = false,
    this.onRoll,
    this.onTokenTap,
  });

  @override
  ConsumerState createState() => _ImageDiceState();
}

class _ImageDiceState extends ConsumerState<ImageDiceWidget> {


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ludoStateNotifier(widget.gameId));

    // Sample dice values for now — replace with actual state values later
    final List<int> diceValues = state.dice ?? [];
    int currentRollPlayerId = state.turn ?? 0;
    final int singleDiceValue = 1;

    if (widget.isThreeDices) {
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
                ),
                onPressed: () => widget.onRoll?.call(currentRollPlayerId),
                child: Text(
                  "P${currentRollPlayerId}\nRoll", // Replace 171 with actual current turn
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(diceValues.length, (index) {
              final int diceVal = index < diceValues.length ? diceValues[index] : 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.onTokenTap?.call(currentRollPlayerId, diceVal),
                  child: widget.isRolling
                      ? Image.asset("assets/images/dice/draw.gif", fit: BoxFit.contain)
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
        color: Colors.white.withOpacity(0), // replace with actual highlight logic
        ripplesCount: 3,
        minRadius: 8,
        maxRadius: 16,
        repeat: true,
        child: CupertinoButton(
          onPressed: () {
            // Replace with roll logic
          },
          padding: EdgeInsets.zero,
          child: widget.isRolling
              ? Image.asset("assets/images/dice/draw.gif", fit: BoxFit.contain)
              : Image.asset("assets/images/dice/$singleDiceValue.png", fit: BoxFit.contain),
        ),
      );
    }
  }


}




// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:frontend/ludo_image_board/constants.dart';
// import 'package:frontend/ludo_image_board/ludo_provider.dart';
// import 'package:frontend/ludo_image_board/ludo_state_notifier.dart';
// import 'package:provider/provider.dart';
// import 'package:simple_ripple_animation/simple_ripple_animation.dart';
//
// ///Widget for the dice
//
// class ImageDiceWidget extends ConsumerWidget {
//   final int gameId;
//   final bool isThreeDices;
//   const ImageDiceWidget({
//     super.key,
//     required this.gameId,
//     this.isThreeDices = false,
//   });
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
