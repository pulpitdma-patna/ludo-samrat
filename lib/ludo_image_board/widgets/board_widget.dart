// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:frontend/app_images.dart';
// import 'package:frontend/ludo_image_board/constants.dart';
// import 'package:frontend/ludo_image_board/ludo_provider.dart';
// import 'package:frontend/ludo_image_board/widgets/pawn_widget.dart';
// import 'package:frontend/theme.dart';
// import 'package:frontend/utils/svg_icon.dart';
// import 'package:provider/provider.dart';
//
// import '../ludo_player.dart';

// ///Widget for the board
// class ImageBoardWidget extends StatelessWidget {
//   final int gameId;
//   final bool isThreeDices;
//   const ImageBoardWidget({super.key,required this.gameId,this.isThreeDices = false});
//
//   ///Return board size
//   double ludoBoard(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     if (width > 500) {
//       return 500;
//     } else {
//       if (width < 300) {
//         return 300;
//       } else {
//         return width - 20;
//       }
//     }
//   }
//
//   ///Count box size
//   double boxStepSize(BuildContext context) {
//     return ludoBoard(context) / 15;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(10),
//       clipBehavior: Clip.antiAlias,
//       width: ludoBoard(context),
//       height: ludoBoard(context),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(40),
//         image: const DecorationImage(
//           image: AssetImage("assets/images/board.png"),
//           fit: BoxFit.cover,
//           alignment: Alignment.topCenter,
//         ),
//       ),
//       child: Consumer<LudoProvider>(
//         builder: (context, value, child) {
//           //We use `Stack` to put all widgets on top of each other
//           //so we make some logic to change the order of players to make sure
//           //the player on top is the one who is playing
//           List<LudoPlayer> players = List.from(value.players);
//           Map<String, List<PawnWidget>> pawnsRaw = {};
//           Map<String, List<String>> pawnsToPrint = {};
//           List<Widget> playersPawn = [];
//
//           //Sort players by current turn to make sure the player on top is the one who is playing
//           players.sort((a, b) => value.currentPlayer.type == a.type ? 1 : -1);
//
//           ///Loop through all players and add their pawns to the map
//           for (int i = 0; i < players.length; i++) {
//             var player = players[i];
//             for (int j = 0; j < player.pawns.length; j++) {
//               var pawn = player.pawns[j];
//               if (pawn.step > -1) {
//                 String step = player.path[pawn.step].toString();
//                 if (pawnsRaw[step] == null) {
//                   pawnsRaw[step] = [];
//                   pawnsToPrint[step] = [];
//                 }
//                 pawnsRaw[step]!.add(pawn);
//                 pawnsToPrint[step]!.add(player.type.toString());
//               } else {
//                 if (pawnsRaw["home"] == null) {
//                   pawnsRaw["home"] = [];
//                   pawnsToPrint["home"] = [];
//                 }
//                 pawnsRaw["home"]!.add(pawn);
//                 pawnsToPrint["home"]!.add(player.type.toString());
//               }
//             }
//           }
//
//           for (int i = 0; i < pawnsRaw.keys.length; i++) {
//             String key = pawnsRaw.keys.elementAt(i);
//             List<PawnWidget> pawnsValue = pawnsRaw[key]!;
//
//             /// This is for every pawn in home
//             if (key == "home") {
//
//               if (key == "home") {
//                 playersPawn.addAll(
//                   pawnsValue.map((e) {
//                     var player = value.players.firstWhere((element) => element.type == e.type);
//
//                     // 🟢 If isThreeDices, show pawns at their first path position instead of home
//                     if (isThreeDices) {
//                       final List<double> pathCoords = player.path[0]; // 1st position on path
//                       return AnimatedPositioned(
//                         key: ValueKey("${e.type.name}_${e.index}"),
//                         left: LudoPath.stepBox(ludoBoard(context), pathCoords[0]),
//                         top: LudoPath.stepBox(ludoBoard(context), pathCoords[1]),
//                         width: boxStepSize(context),
//                         height: boxStepSize(context),
//                         duration: const Duration(milliseconds: 200),
//                         child: e,
//                       );
//                     } else {
//                       return AnimatedPositioned(
//                         key: ValueKey("${e.type.name}_${e.index}"),
//                         left: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][0]),
//                         top: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][1]),
//                         width: boxStepSize(context),
//                         height: boxStepSize(context),
//                         duration: const Duration(milliseconds: 200),
//                         child: e,
//                       );
//                     }
//                   }),
//                 );
//               }
//
//
//               // playersPawn.addAll(
//               //   pawnsValue.map((e) {
//               //     var player = value.players.firstWhere((element) => element.type == e.type);
//               //     return AnimatedPositioned(
//               //       key: ValueKey("${e.type.name}_${e.index}"),
//               //       left: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][0]),
//               //       top: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][1]),
//               //       width: boxStepSize(context),
//               //       height: boxStepSize(context),
//               //       duration: const Duration(milliseconds: 200),
//               //       child: e,
//               //     );
//               //   }),
//               // );
//             } else {
//               // This is for every pawn in path (not in home)
//               // I'm so lazy, so make it simple h3h3
//               List<double> coordinates = key.replaceAll("[", "").replaceAll("]", "").split(",").map((e) => double.parse(e.trim())).toList();
//
//               if (pawnsValue.length == 1) {
//                 // This is for 1 pawn in 1 box
//                 var e = pawnsValue.first;
//                 playersPawn.add(AnimatedPositioned(
//                   key: ValueKey("${e.type.name}_${e.index}"),
//                   duration: const Duration(milliseconds: 200),
//                   left: LudoPath.stepBox(ludoBoard(context), coordinates[0]),
//                   top: LudoPath.stepBox(ludoBoard(context), coordinates[1]),
//                   width: boxStepSize(context),
//                   height: boxStepSize(context),
//                   child: pawnsValue.first,
//                 ));
//               } else {
//                 // This is for more than 1 pawn in 1 box
//                 playersPawn.addAll(
//                   List.generate(
//                     pawnsValue.length,
//                         (index) {
//                       var e = pawnsValue[index];
//                       return AnimatedPositioned(
//                         key: ValueKey("${e.type.name}_${e.index}"),
//                         duration: const Duration(milliseconds: 200),
//                         left: LudoPath.stepBox(ludoBoard(context), coordinates[0]) + (index * 3),
//                         top: LudoPath.stepBox(ludoBoard(context), coordinates[1]),
//                         width: boxStepSize(context) - 5,
//                         height: boxStepSize(context),
//                         child: pawnsValue[index],
//                       );
//                     },
//                   ),
//                 );
//               }
//             }
//           }
//
//           return Center(
//             child: Stack(
//               fit: StackFit.expand,
//               alignment: Alignment.center,
//               children: [
//                 ...playersPawn,
//                 ...winners(context, value.winners),
//                 turnIndicator(
//                   context,
//                   value.currentPlayer.type,
//                   value.currentPlayer.color,
//                   value.gameState,
//                   isThreeDices: isThreeDices,
//                   points: {173: 0, 174: 0},
//                   playerIdMap: {
//
//                   },
//                 )
//                 // turnIndicator(context, value.currentPlayer.type, value.currentPlayer.color, value.gameState,isThreeDices: isThreeDices, points: {}, playerIdMap: {},),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   ///This is for the turn indicator widget
//   Widget turnIndicator(BuildContext context, LudoPlayerType turn, Color color, LudoGameState stage,{  required bool isThreeDices, required Map<int, int> points, required Map<LudoPlayerType, int> playerIdMap,}) {
//     //0 is left, 1 is right
//     int x = 0;
//     //0 is top, 1 is bottom
//     int y = 0;
//
//     switch (turn) {
//       case LudoPlayerType.green:
//         x = 0;
//         y = 0;
//         break;
//       case LudoPlayerType.yellow:
//         x = 1;
//         y = 0;
//         break;
//       case LudoPlayerType.blue:
//         x = 1;
//         y = 1;
//         break;
//       case LudoPlayerType.red:
//         x = 0;
//         y = 1;
//         break;
//     }
//     String stageText = "Roll the dice";
//     switch (stage) {
//       case LudoGameState.throwDice:
//         stageText = "Roll the dice";
//         break;
//       case LudoGameState.moving:
//         stageText = "Pawn is moving...";
//         break;
//       case LudoGameState.pickPawn:
//         stageText = "Pick a pawn";
//         break;
//       case LudoGameState.finish:
//         stageText = "Game is over";
//         break;
//     }
//     int playerId = playerIdMap[turn] ?? 0;
//     int playerScore = points[playerId] ?? 0;
//
//     return Positioned(
//       top: y == 0 ? 0 : null,
//       left: x == 0 ? 0 : null,
//       right: x == 1 ? 0 : null,
//       bottom: y == 1 ? 0 : null,
//       width: ludoBoard(context) * .4,
//       height: ludoBoard(context) * .4,
//       child: IgnorePointer(
//         child: Padding(
//           padding: EdgeInsets.all(boxStepSize(context)),
//           child: Container(
//             alignment: Alignment.center,
//             clipBehavior: Clip.antiAlias,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: isThreeDices
//                 ? Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "Your Score",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//                 Text(
//                   "$playerScore",
//                   style: const TextStyle(
//                     fontSize: 22,
//                     color: Colors.black,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 )
//               ],
//             )
//                 : RichText(
//               textAlign: TextAlign.center,
//               text: TextSpan(
//                 style: TextStyle(fontSize: 8, color: color),
//                 children: [
//                   const TextSpan(
//                     text: "Your turn!\n",
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   TextSpan(
//                     text: stageText,
//                     style: const TextStyle(color: Colors.black),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   ///This is for the winner widget
//   List<Widget> winners(BuildContext context, List<LudoPlayerType> winners) => List.generate(
//     winners.length,
//         (index) {
//       Widget crownImage = Image.asset("assets/games/ludo/crown/1st.png");
//
//       //0 is left, 1 is right
//       int x = 0;
//       //0 is top, 1 is bottom
//       int y = 0;
//
//       if (index == 0) {
//         crownImage = Image.asset("assets/images/crown/1st.png", fit: BoxFit.cover);
//       } else if (index == 1) {
//         crownImage = Image.asset("assets/images/crown/2nd.png", fit: BoxFit.cover);
//       } else if (index == 2) {
//         crownImage = Image.asset("assets/images/crown/3rd.png", fit: BoxFit.cover);
//       } else {
//         return Container();
//       }
//
//       switch (winners[index]) {
//         case LudoPlayerType.green:
//           x = 0;
//           y = 0;
//           break;
//         case LudoPlayerType.yellow:
//           x = 1;
//           y = 0;
//           break;
//         case LudoPlayerType.blue:
//           x = 1;
//           y = 1;
//           break;
//         case LudoPlayerType.red:
//           x = 0;
//           y = 1;
//           break;
//       }
//       return Positioned(
//         top: y == 0 ? 0 : null,
//         left: x == 0 ? 0 : null,
//         right: x == 1 ? 0 : null,
//         bottom: y == 1 ? 0 : null,
//         width: ludoBoard(context) * .4,
//         height: ludoBoard(context) * .4,
//         child: Padding(
//           padding: EdgeInsets.all(boxStepSize(context)),
//           child: Container(
//             clipBehavior: Clip.antiAlias,
//             decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
//             child: crownImage,
//           ),
//         ),
//       );
//     },
//   );
//
//   List<Widget> buildAvatars(Map<int, int> corners) {
//     // final state = ref.watch(gameStateProvider(widget.gameId));
//
//     final alignments = [
//       Alignment.topLeft,
//       Alignment.topRight,
//       Alignment.bottomLeft,
//       Alignment.bottomRight,
//     ];
//
//     // Helper to render dice face (SVG or fallback text)
//     Widget _buildDiceFace(int value, double size) {
//       final path = 'assets/images/dice3d_$value.svg';
//
//       return FutureBuilder<bool>(
//         future: rootBundle.load(path).then((_) => true).catchError((_) => false),
//         builder: (context, snapshot) {
//           final hasAsset = snapshot.data == true;
//           final Widget child = hasAsset
//               ? SvgPicture.asset(path, width: size * 0.8, height: size * 0.8)
//               : Text(
//             '$value',
//             style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.bold),
//           );
//
//           return Container(
//             width: size,
//             height: size,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
//               ],
//             ),
//             child: child,
//           );
//         },
//       );
//     }
//
//     final widgets = <Widget>[];
//
//     corners.forEach((pid, corner) {
//       if (corner < alignments.length) {
//         // Layout rules
//         bool nameOnTop = (corner == 2 || corner == 3); // bottom corners
//         bool avatarOnLeft = (corner == 1 || corner == 3); // topRight & bottomRight
//         bool sideProfileOnLeft = !avatarOnLeft;
//
//         // Name container
//         Widget nameWidget = Container(
//           width: 126.w,
//           decoration: BoxDecoration(
//             color: Colors.grey,
//             borderRadius: BorderRadius.circular(2.r),
//           ),
//           child: Text(
//             'P$pid',
//             textAlign: TextAlign.center,
//             style: AppTextStyles.poppinsMedium.copyWith(
//               fontSize: 12.sp,
//               color: Colors.black,
//             ),
//           ),
//         );
//
//         // Show selected dice in 56x56 container
//         // final diceValue = state.selectedDie ?? 0;
//         Widget avatarBox =  Container(
//           height: 56.w,
//           width: 56.w,
//           decoration: BoxDecoration(
//             color: Colors.black54,
//             border: Border.all(color: AppColors.white.withOpacity(0.3)),
//             borderRadius: BorderRadius.circular(4.r),
//           ),
//         );
//
//         // Profile icon container
//         Widget sideProfile = Container(
//           height: 46.w,
//           width: 46.w,
//           decoration: BoxDecoration(
//             color: Colors.black26,
//             borderRadius: BorderRadius.circular(2.r),
//           ),
//           child: svgIcon(
//             name: AppImages.profile,
//             width: 26.w,
//             height: 24.h,
//             color: Colors.grey,
//           ),
//         );
//
//         // Arrange avatar row
//         List<Widget> avatarRowChildren = sideProfileOnLeft
//             ? [sideProfile, SizedBox(width: 4.w), avatarBox]
//             : [avatarBox, SizedBox(width: 4.w), sideProfile];
//
//         // Assemble avatar column
//         Widget avatar = Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             if (nameOnTop) nameWidget,
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: avatarRowChildren,
//             ),
//             if (!nameOnTop) nameWidget,
//           ],
//         );
//
//         // Final aligned container
//         widgets.add(
//           Align(
//             alignment: alignments[corner],
//             child: Container(
//               height: 90.h,
//               width: 126.w,
//               margin: EdgeInsets.only(
//                 bottom: (corner == 0 || corner == 1) ? 8.h : 0,
//                 top: (corner == 2 || corner == 3) ? 8.h : 0,
//               ),
//               padding: EdgeInsets.symmetric(horizontal: 4.w),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: null,
//                 boxShadow: [
//                   BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
//                 ],
//               ),
//               child: avatar,
//             ),
//           ),
//         );
//       }
//     });
//
//     return widgets;
//   }
//
// }














import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/ludo_image_board/constants.dart';
import 'package:frontend/ludo_image_board/ludo_state_notifier.dart';
import 'package:frontend/ludo_image_board/widgets/pawn_widget.dart';

import '../ludo_player.dart';

///Widget for the board

class ImageBoardWidget extends ConsumerStatefulWidget {
  final int gameId;
  final bool isThreeDices;
  final List<Widget> playersPawn;
  const ImageBoardWidget({super.key,
    required this.gameId,
    this.isThreeDices = false,
    required this.playersPawn
  });

  @override
  ConsumerState createState() => _ImageBoardWidgetState();
}

class _ImageBoardWidgetState extends ConsumerState<ImageBoardWidget> {

  ///Return board size
  double ludoBoard(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 500) {
      return 500;
    } else {
      if (width < 300) {
        return 300;
      } else {
        return width - 20;
      }
    }
  }

  ///Count box size
  double boxStepSize(BuildContext context) {
    return ludoBoard(context) / 15;
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      width: ludoBoard(context),
      height: ludoBoard(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        image: const DecorationImage(
          image: AssetImage("assets/images/board.png"),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Consumer(
        builder: (context, ref, child) {
          final notificationsState = ref.watch(ludoStateNotifier(widget.gameId));
          controller() => ref.read(ludoStateNotifier(widget.gameId).notifier);

          //We use `Stack` to put all widgets on top of each other
          //so we make some logic to change the order of players to make sure
          //the player on top is the one who is playing
          List<LudoPlayer> players = List.from(controller().players);
          Map<String, List<PawnWidget>> pawnsRaw = {};
          Map<String, List<String>> pawnsToPrint = {};
          List<Widget> playersPawn = [];

          final newPositions = notificationsState.positions;


          //Sort players by current turn to make sure the player on top is the one who is playing
          // final currentId = controller().players;
          // players.sort((a, b) {
          //   if (a.playerId == currentId) return -1;
          //   if (b.playerId == currentId) return 1;
          //
          //   final order = controller().playerOrder;
          //   return order!.indexOf(a.playerId).compareTo(order.indexOf(b.playerId));
          // });
          // players.sort((a, b) => controller().currentPlayer.type == a.type ? 1 : -1);


          ///Loop through all players and add their pawns to the map
          for (int i = 0; i < players.length; i++) {
            var player = players[i];
            for (int j = 0; j < player.pawns.length; j++) {
              var pawn = player.pawns[j];
              if (pawn.step > -1) {
                String step = player.path[pawn.step].toString();
                if (pawnsRaw[step] == null) {
                  pawnsRaw[step] = [];
                  pawnsToPrint[step] = [];
                }
                pawnsRaw[step]!.add(pawn);
                pawnsToPrint[step]!.add(player.type.toString());
              } else {
                if (pawnsRaw["home"] == null) {
                  pawnsRaw["home"] = [];
                  pawnsToPrint["home"] = [];
                }
                pawnsRaw["home"]!.add(pawn);
                pawnsToPrint["home"]!.add(player.type.toString());
              }
            }
          }

          for (int i = 0; i < pawnsRaw.keys.length; i++) {
            String key = pawnsRaw.keys.elementAt(i);
            List<PawnWidget> pawnsValue = pawnsRaw[key]!;

            /// This is for every pawn in home
            if (key == "home") {
              playersPawn.addAll(
                pawnsValue.map((e) {
                  var player = controller().players.firstWhere((element) => element.type == e.type);
                  return AnimatedPositioned(
                    key: ValueKey("${e.type.name}_${e.index}"),
                    left: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][0]),
                    top: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][1]),
                    width: boxStepSize(context),
                    height: boxStepSize(context),
                    duration: const Duration(milliseconds: 200),
                    child: e,
                  );
                }),
              );
            } else {
              // This is for every pawn in path (not in home)
              List<double> coordinates = key.replaceAll("[", "").replaceAll("]", "").split(",").map((e) => double.parse(e.trim())).toList();

              if (pawnsValue.length == 1) {
                // This is for 1 pawn in 1 box
                var e = pawnsValue.first;
                playersPawn.add(AnimatedPositioned(
                  key: ValueKey("${e.type.name}_${e.index}"),
                  duration: const Duration(milliseconds: 200),
                  left: LudoPath.stepBox(ludoBoard(context), coordinates[0]),
                  top: LudoPath.stepBox(ludoBoard(context), coordinates[1]),
                  width: boxStepSize(context),
                  height: boxStepSize(context),
                  child: pawnsValue.first,
                ));
              } else {
                // This is for more than 1 pawn in 1 box
                playersPawn.addAll(
                  List.generate(
                    pawnsValue.length,
                        (index) {
                      var e = pawnsValue[index];
                      return AnimatedPositioned(
                        key: ValueKey("${e.type.name}_${e.index}"),
                        duration: const Duration(milliseconds: 200),
                        left: LudoPath.stepBox(ludoBoard(context), coordinates[0]) + (index * 3),
                        top: LudoPath.stepBox(ludoBoard(context), coordinates[1]),
                        width: boxStepSize(context) - 5,
                        height: boxStepSize(context),
                        child: pawnsValue[index],
                      );
                    },
                  ),
                );
              }
            }
          }



          return Center(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                if(widget.isThreeDices)
                ...controller().players.map(
                      (player) => scoreBox(
                    context: context,
                    player: player,
                    points: controller().points,
                  ),
                ),
                if(!widget.isThreeDices)
                  turnIndicator(context, controller().currentPlayer.type, controller().currentPlayer.color, controller().gameState),
                ...widget.playersPawn,
                // ...playersPawn,
                ...winners(context, controller().winners),

              ],
            ),
          );
        },
      ),
      // child: Center(
      //   child: Stack(
      //     fit: StackFit.expand,
      //     alignment: Alignment.center,
      //     children: [
      //       ...playersPawn,
      //       ...winners(context, controller().winners),
      //       turnIndicator(context, controller().currentPlayer.type, controller().currentPlayer.color, controller().gameState),
      //     ],
      //   ),
      // ),
    );
  }




  ///This is for the turn indicator widget
  Widget turnIndicator(BuildContext context, LudoPlayerType turn, Color color, LudoGameState stage) {
    //0 is left, 1 is right
    int x = 0;
    //0 is top, 1 is bottom
    int y = 0;

    switch (turn) {
      case LudoPlayerType.green:
        x = 0;
        y = 0;
        break;
      case LudoPlayerType.yellow:
        x = 1;
        y = 0;
        break;
      case LudoPlayerType.blue:
        x = 1;
        y = 1;
        break;
      case LudoPlayerType.red:
        x = 0;
        y = 1;
        break;
    }
    String stageText = "Roll the dice";
    switch (stage) {
      case LudoGameState.throwDice:
        stageText = "Roll the dice";
        break;
      case LudoGameState.moving:
        stageText = "Pawn is moving...";
        break;
      case LudoGameState.pickPawn:
        stageText = "Pick a pawn";
        break;
      case LudoGameState.finish:
        stageText = "Game is over";
        break;
    }
    return Positioned(
      top: y == 0 ? 0 : null,
      left: x == 0 ? 0 : null,
      right: x == 1 ? 0 : null,
      bottom: y == 1 ? 0 : null,
      width: ludoBoard(context) * .4,
      height: ludoBoard(context) * .4,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(boxStepSize(context)),
          child: Container(
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(style: TextStyle(fontSize: 8, color: color), children: [
                  const TextSpan(text: "Your turn!\n", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  TextSpan(text: stageText, style: const TextStyle(color: Colors.black)),
                ]),
              )),
        ),
      ),
    );
  }

  Widget scoreBox({
    required BuildContext context,
    required LudoPlayer player,
    required Map<int, int> points,
  }) {
    int x = 0; // 0 = left, 1 = right
    int y = 0; // 0 = top, 1 = bottom

    switch (player.type) {
      case LudoPlayerType.green:
        x = 0;
        y = 0;
        break;
      case LudoPlayerType.yellow:
        x = 1;
        y = 0;
        break;
      case LudoPlayerType.blue:
        x = 1;
        y = 1;
        break;
      case LudoPlayerType.red:
        x = 0;
        y = 1;
        break;
    }

    final playerScore = points[player.playerId] ?? 0;

    return Positioned(
      top: y == 0 ? 0 : null,
      left: x == 0 ? 0 : null,
      right: x == 1 ? 0 : null,
      bottom: y == 1 ? 0 : null,
      width: ludoBoard(context) * .4,
      height: ludoBoard(context) * .4,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(boxStepSize(context)),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            clipBehavior: Clip.antiAlias,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 10, color: player.color),
                children: [
                  const TextSpan(
                    text: "Score\n",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "$playerScore",
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  ///This is for the winner widget
  List<Widget> winners(BuildContext context, List<LudoPlayerType> winners) => List.generate(
    winners.length,
        (index) {
      Widget crownImage = Image.asset("assets/games/ludo/crown/1st.png");

      //0 is left, 1 is right
      int x = 0;
      //0 is top, 1 is bottom
      int y = 0;

      if (index == 0) {
        crownImage = Image.asset("assets/images/crown/1st.png", fit: BoxFit.cover);
      } else if (index == 1) {
        crownImage = Image.asset("assets/images/crown/2nd.png", fit: BoxFit.cover);
      } else if (index == 2) {
        crownImage = Image.asset("assets/images/crown/3rd.png", fit: BoxFit.cover);
      } else {
        return Container();
      }

      switch (winners[index]) {
        case LudoPlayerType.green:
          x = 0;
          y = 0;
          break;
        case LudoPlayerType.yellow:
          x = 1;
          y = 0;
          break;
        case LudoPlayerType.blue:
          x = 1;
          y = 1;
          break;
        case LudoPlayerType.red:
          x = 0;
          y = 1;
          break;
      }
      return Positioned(
        top: y == 0 ? 0 : null,
        left: x == 0 ? 0 : null,
        right: x == 1 ? 0 : null,
        bottom: y == 1 ? 0 : null,
        width: ludoBoard(context) * .4,
        height: ludoBoard(context) * .4,
        child: Padding(
          padding: EdgeInsets.all(boxStepSize(context)),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            child: crownImage,
          ),
        ),
      );
    },
  );

}
