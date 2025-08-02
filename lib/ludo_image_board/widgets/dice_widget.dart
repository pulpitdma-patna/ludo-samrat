import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/ludo_image_board/constants.dart';
import 'package:frontend/ludo_image_board/ludo_provider.dart';
import 'package:provider/provider.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

///Widget for the dice
class ImageDiceWidget extends StatelessWidget {
  const ImageDiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LudoProvider>(
      // builder: (context, value, child) {
      //   return CupertinoButton(
      //     onPressed: value.throwDice,
      //     padding: const EdgeInsets.only(),
      //     child: value.diceStarted ? Image.asset("assets/images/dice/draw.gif", fit: BoxFit.contain) : Image.asset("assets/images/dice/${value.diceResult}.png", fit: BoxFit.contain),
      //   );
      // },
      builder: (context, value, child) => RippleAnimation(
        color: value.gameState == LudoGameState.throwDice ? value.currentPlayer.color : Colors.white.withOpacity(0),
        ripplesCount: 3,
        minRadius: 10,
        maxRadius: 20.r,
        repeat: true,
        child: CupertinoButton(
          onPressed: value.throwDice,
          padding: const EdgeInsets.only(),
          child: value.diceStarted ? Image.asset("assets/images/dice/draw.gif", fit: BoxFit.contain) : Image.asset("assets/images/dice/${value.diceResult}.png", fit: BoxFit.contain),
        ),
      ),
    );
  }
}
