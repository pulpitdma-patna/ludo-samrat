// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:frontend/common_widget/app_scaffold.dart';
// import 'package:frontend/common_widget/common_appbar.dart';
// import 'package:frontend/constants.dart';
// import 'package:frontend/ludo_image_board/ludo_provider.dart';
// import 'package:frontend/ludo_image_board/widgets/board_widget.dart';
// import 'package:frontend/ludo_image_board/widgets/dice_widget.dart';
// import 'package:frontend/theme.dart';
// import 'package:frontend/utils/svg_icon.dart';
// import 'package:frontend/widgets/app_drawer.dart';
// import 'package:provider/provider.dart';
//
// import '../app_images.dart' show AppImages;
//
// class MainScreen extends StatefulWidget {
//   final int gameId;
//   final Map<String, dynamic>? gameData;
//   const MainScreen({super.key,required this.gameId,this.gameData});
//
//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }
//
// class _MainScreenState extends State<MainScreen> {
//
//   Map<String,dynamic> _gamData = {};
//   bool _isThreeDices = false;
//
//   @override
//   void initState() {
//     context.read<LudoProvider>().startGame();
//     if(widget.gameData != null){
//       debugPrint("Data -=--${widget.gameData}");
//       _gamData = widget.gameData!;
//       if(_gamData['engine'] == 'three_dice'){
//         _isThreeDices = true;
//       }
//     }
//     super.initState();
//   }
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
//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       backgroundGradient: AppGradients.blueHorizontal,
//       drawer: const AppDrawer(),
//       appBar: GradientAppBar(
//         leading: InkWell(
//           // onTap: () async {
//           //   final shouldPop = await _onWillPop();
//           //   if (shouldPop && mounted && context.canPop()) {
//           //     context.pop();
//           //   }
//           // },
//           child: Container(
//             width: 28.w,
//             height: 28.w,
//             decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.transparent,
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.arrow_back,
//                 size: 22.h,
//                 color: AppColors.white,
//               ),
//             ),
//           ),
//         ),
//         title: Row(
//           children: [
//             Text(
//               'Game ${widget.gameId}',
//               style: AppTextStyles.poppinsSemiBold.copyWith(
//                 fontSize: 18.sp,
//                 color: AppColors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             height: ludoBoard(context) + 210.h,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                  Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     ImageBoardWidget(gameId: widget.gameId,isThreeDices: _isThreeDices,),
//                     // Center(child: SizedBox( height: 50,child: ImageDiceWidget(gameId: widget.gameId,isThreeDices: _isThreeDices,))),
//                   ],
//                 ),
//                 ... buildAvatars(_isThreeDices ? {171:0,172:3} : {171:0,172:1,173:2,174:3,}),
//                  Consumer<LudoProvider>(
//                   builder: (context, value, child) => value.winners.length == 3
//                       ? Container(
//                           color: Colors.black.withOpacity(0.8),
//                           child: Center(
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Image.asset("assets/images/thankyou.gif"),
//                                 const Text("Thank you for playing 😙", style: TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
//                                 Text("The Winners is: ${value.winners.map((e) => e.name.toUpperCase()).join(", ")}", style: const TextStyle(color: Colors.white, fontSize: 30), textAlign: TextAlign.center),
//                                 const Divider(color: Colors.white),
//                                 const Text("This game made with Flutter ❤️ by Mochamad Nizwar Syafuan", style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center),
//                                 const SizedBox(height: 20),
//                                 const Text("Refresh your browser to play again", style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
//                               ],
//                             ),
//                           ),
//                         )
//                       : const SizedBox.shrink(),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(vertical: 16.h),
//             child: Center(child: SizedBox( height: 50,child: ImageDiceWidget(gameId: widget.gameId,isThreeDices: _isThreeDices,))),
//           ),
//         ],
//       ),
//     );
//   }
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
//     final cornerColor = [
//       Colors.green,
//       Colors.yellow,
//       Colors.red,
//       Colors.blue,
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
//             color: cornerColor[corner],
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
//             // color: Colors.black54,
//             border: Border.all(color: AppColors.white.withOpacity(0.3)),
//             borderRadius: BorderRadius.circular(4.r),
//           ),
//           child: Image.asset(
//             "assets/images/dice/${1}.png",
//             // width: 40,
//             // height: 40,
//             fit: BoxFit.cover,
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







import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/ludo_image_board/constants.dart';
import 'package:frontend/ludo_image_board/ludo_player.dart';
import 'package:frontend/ludo_image_board/ludo_provider.dart';
import 'package:frontend/ludo_image_board/ludo_state_notifier.dart';
import 'package:frontend/ludo_image_board/widgets/board_widget.dart';
import 'package:frontend/ludo_image_board/widgets/dice_widget.dart';
import 'package:frontend/ludo_image_board/widgets/pawn_widget.dart';
import 'package:frontend/providers/game_provider.dart';
import 'package:frontend/services/analytics_service.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/services/quickplay_api.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../widgets/app_drawer.dart';


class MainScreen extends ConsumerStatefulWidget {
  final int gameId;
  final Map<String, dynamic>? gameData;
  const MainScreen({super.key,required this.gameId,this.gameData});

  @override
  ConsumerState createState() => _MainScreen2State();
}

class _MainScreen2State extends ConsumerState<MainScreen> {

  StreamSubscription? _winnerSub;
  ProviderSubscription<LudoState>? _gameStateSub;

  Map<String,dynamic> _gamData = {};
  bool _isThreeDices = false;
  bool _rolling = false;
  Timer? _rollTimeout;

  List<LudoPlayer> players = [];
  Map<String, List<PawnWidget>> pawnsRaw = {};
  Map<String, List<String>> pawnsToPrint = {};
  List<Widget> playersPawn = [];



  //   ///Return board size
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
  void initState() {
    final notifier = ref.read(ludoStateNotifier(widget.gameId).notifier);
    unawaited(notifier.connect(widget.gameId.toString()));
        if(widget.gameData != null){
      debugPrint("Data -=--${widget.gameData}");
      _gamData = widget.gameData!;
      if(_gamData['engine'] == 'three_dice'){
        _isThreeDices = true;
      }
    }

    // for (int i = 0; i < players.length; i++) {
    //   var player = players[i];
    //   for (int j = 0; j < player.pawns.length; j++) {
    //     var pawn = player.pawns[j];
    //     if (pawn.step > -1) {
    //       String step = player.path[pawn.step].toString();
    //       if (pawnsRaw[step] == null) {
    //         pawnsRaw[step] = [];
    //         pawnsToPrint[step] = [];
    //       }
    //       pawnsRaw[step]!.add(pawn);
    //       pawnsToPrint[step]!.add(player.type.toString());
    //     } else {
    //       if (pawnsRaw["home"] == null) {
    //         pawnsRaw["home"] = [];
    //         pawnsToPrint["home"] = [];
    //       }
    //       pawnsRaw["home"]!.add(pawn);
    //       pawnsToPrint["home"]!.add(player.type.toString());
    //     }
    //   }
    // }
    //
    // for (int i = 0; i < pawnsRaw.keys.length; i++) {
    //   String key = pawnsRaw.keys.elementAt(i);
    //   List<PawnWidget> pawnsValue = pawnsRaw[key]!;
    //
    //   /// This is for every pawn in home
    //   if (key == "home") {
    //     playersPawn.addAll(
    //       pawnsValue.map((e) {
    //         var player = notifier.players.firstWhere((element) => element.type == e.type);
    //         return AnimatedPositioned(
    //           key: ValueKey("${e.type.name}_${e.index}"),
    //           left: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][0]),
    //           top: LudoPath.stepBox(ludoBoard(context), player.homePath[e.index][1]),
    //           width: boxStepSize(context),
    //           height: boxStepSize(context),
    //           duration: const Duration(milliseconds: 200),
    //           child: e,
    //         );
    //       }),
    //     );
    //   } else {
    //     // This is for every pawn in path (not in home)
    //     List<double> coordinates = key.replaceAll("[", "").replaceAll("]", "").split(",").map((e) => double.parse(e.trim())).toList();
    //
    //     if (pawnsValue.length == 1) {
    //       // This is for 1 pawn in 1 box
    //       var e = pawnsValue.first;
    //       playersPawn.add(AnimatedPositioned(
    //         key: ValueKey("${e.type.name}_${e.index}"),
    //         duration: const Duration(milliseconds: 200),
    //         left: LudoPath.stepBox(ludoBoard(context), coordinates[0]),
    //         top: LudoPath.stepBox(ludoBoard(context), coordinates[1]),
    //         width: boxStepSize(context),
    //         height: boxStepSize(context),
    //         child: pawnsValue.first,
    //       ));
    //     } else {
    //       // This is for more than 1 pawn in 1 box
    //       playersPawn.addAll(
    //         List.generate(
    //           pawnsValue.length,
    //               (index) {
    //             var e = pawnsValue[index];
    //             return AnimatedPositioned(
    //               key: ValueKey("${e.type.name}_${e.index}"),
    //               duration: const Duration(milliseconds: 200),
    //               left: LudoPath.stepBox(ludoBoard(context), coordinates[0]) + (index * 3),
    //               top: LudoPath.stepBox(ludoBoard(context), coordinates[1]),
    //               width: boxStepSize(context) - 5,
    //               height: boxStepSize(context),
    //               child: pawnsValue[index],
    //             );
    //           },
    //         ),
    //       );
    //     }
    //   }
    // }


    _winnerSub = notifier.socket.stream.listen((data) {
    });
    _gameStateSub = ref.listenManual<LudoState>(
      ludoStateNotifier(widget.gameId),
          (prev, next) {
        if (prev?.dice != next.dice) {
          setState(() {
            _rolling = false;
          });
        }

        if (prev?.positions != next.positions) {
          setState(() {
            _updatePawnData(next);
          });
        }
    },
    );

    super.initState();
  }


  void _updatePawnData(LudoState state) {
    final double contextSize = ludoBoard(context);

    players.clear();
    pawnsRaw.clear();
    pawnsToPrint.clear();
    playersPawn.clear();

    players.addAll(state.players);

    final newPositions = state.positions;
    const Set<int> ignoredSteps = {0, 13, 26, 39};

    // Build pawnsRaw and pawnsToPrint maps
    for (int i = 0; i < players.length; i++) {
      var player = players[i];
      for (int j = 0; j < player.pawns.length; j++) {
        var pawn = player.pawns[j];
        if (pawn.step > -1) {
          String step = player.path[pawn.step].toString();
          pawnsRaw[step] ??= [];
          pawnsToPrint[step] ??= [];
          pawnsRaw[step]!.add(pawn);
          pawnsToPrint[step]!.add(player.type.toString());
        } else {
          pawnsRaw["home"] ??= [];
          pawnsToPrint["home"] ??= [];
          pawnsRaw["home"]!.add(pawn);
          pawnsToPrint["home"]!.add(player.type.toString());
        }
      }
    }

    // Generate UI pawn widgets
    for (String key in pawnsRaw.keys) {
      List<PawnWidget> pawnsValue = pawnsRaw[key]!;

      if (key == "home") {
        playersPawn.addAll(
          pawnsValue.map((e) {
            var player = players.firstWhere((element) => element.type == e.type);
            return AnimatedPositioned(
              key: ValueKey("${e.type.name}_${e.index}"),
              left: LudoPath.stepBox(contextSize, player.homePath[e.index][0]),
              top: LudoPath.stepBox(contextSize, player.homePath[e.index][1]),
              width: boxStepSize(context),
              height: boxStepSize(context),
              duration: const Duration(milliseconds: 200),
              child: e,
            );
          }),
        );
      } else {
        List<double> coordinates = key
            .replaceAll("[", "")
            .replaceAll("]", "")
            .split(",")
            .map((e) => double.parse(e.trim()))
            .toList();

        if (pawnsValue.length == 1) {
          var e = pawnsValue.first;
          playersPawn.add(
            AnimatedPositioned(
              key: ValueKey("${e.type.name}_${e.index}"),
              duration: const Duration(milliseconds: 200),
              left: LudoPath.stepBox(contextSize, coordinates[0]),
              top: LudoPath.stepBox(contextSize, coordinates[1]),
              width: boxStepSize(context),
              height: boxStepSize(context),
              child: e,
            ),
          );
        } else {
          playersPawn.addAll(
            List.generate(pawnsValue.length, (index) {
              var e = pawnsValue[index];
              return AnimatedPositioned(
                key: ValueKey("${e.type.name}_${e.index}"),
                duration: const Duration(milliseconds: 200),
                left: LudoPath.stepBox(contextSize, coordinates[0]) + (index * 3),
                top: LudoPath.stepBox(contextSize, coordinates[1]),
                width: boxStepSize(context) - 5,
                height: boxStepSize(context),
                child: e,
              );
            }),
          );
        }
      }
    }

    for (final player in players) {
      final int playerId = player.playerId;

      if (!newPositions.containsKey(playerId)) continue;

      final List<int> newPawnSteps = newPositions[playerId]!;

      for (int i = 0; i < newPawnSteps.length; i++) {
        final int newStep = newPawnSteps[i];
        final int currentStep = player.pawns[i].step;

        final shouldMove = newStep != currentStep && !ignoredSteps.contains(newStep);

        if (shouldMove) {
          player.movePawn(i, newStep);
        }
      }
    }

  }




  @override
  Widget build(BuildContext context) {

    final state = ref.watch(ludoStateNotifier(widget.gameId));

    return AppScaffold(
      backgroundGradient: AppGradients.blueHorizontal,
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted && context.canPop()) {
              context.pop();
            }
          },
          child: Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back,
                size: 22.h,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'Game ${widget.gameId}',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 18.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: ludoBoard(context) + 210.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Builder(builder: (context) {
                  final state = ref.watch(ludoStateNotifier(widget.gameId));
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ImageBoardWidget(
                        gameId: widget.gameId,
                        isThreeDices: _isThreeDices,
                        playersPawn: playersPawn,
                      ),
                      // Center(child: SizedBox(width: 50, height: 50, child: ImageDiceWidget(gameId: widget.gameId,))),
                    ],
                  );
                },),
                ..._buildAvatars(),
                _winner(state),
                ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(child: SizedBox(
                height: 50,
                child: ImageDiceWidget(
                  gameId: widget.gameId,
                  isThreeDices: _isThreeDices,
                  onTokenTap: _onTokenTap,
                  isRolling: _rolling,
                  onRoll: _sendRoll,
                ))),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8.w),
            const Text('Quit Match?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to quit the match?',
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Quit'),
          ),
        ],
      ),
    );

    if (shouldQuit == true) {
      final roomId = context.read<GameProvider>().roomIdForGame(widget.gameId);
      final matchId = context.read<GameProvider>().matchIdForGame(widget.gameId);

      if (roomId != null && matchId != null) {
        final partsRes = await QuickPlayApi().participants(roomId);
        if (partsRes.isSuccess && partsRes.data != null) {
          final myId = await AppPreferences().getUserId();
          int? winner;
          for (final p in partsRes.data!) {
            final uid = int.tryParse(p['user_id']?.toString() ?? '');
            if (uid != null && uid != myId) {
              winner = uid;
              break;
            }
          }
          if (winner != null) {
            await context.read<GameProvider>().endQuickPlay(
              roomId,
              matchId,
              winner,
              context,
            );
          }
        }
      }

      unawaited(AnalyticsService.logGameEnd(widget.gameId));
      // ref.invalidate(gameStateProvider(widget.gameId));

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
      return false;
    }

    return false;
  }

  void _onTokenTap(int playerId, int tokenIndex) {
    final state = ref.read(ludoStateNotifier(widget.gameId));
    if (_rolling || state.turn != playerId) return;
    if (!(state.allowedMoves[playerId]?.containsKey(tokenIndex) ?? false))
      return;
    _sendMove(playerId, tokenIndex);
  }

  void _sendMove(int playerId, int token) {
    final state = ref.read(ludoStateNotifier(widget.gameId));
    final dest = state.allowedMoves[playerId]?[token];
    final current = state.positions[playerId]?[token];
    if (dest == null || current == null) return;
    final die = state.selectedDie ?? dest - current;
    ref.read(ludoStateNotifier(widget.gameId).notifier).socketMover(playerId, token, die);
    ref.read(ludoStateNotifier(widget.gameId).notifier).selectDie(null);
  }

  void _sendRoll(int playerId) {
    setState(() {
      _rolling = true;
    });
    // _lastDice = null;
    SystemSound.play(SystemSoundType.click);
    ref.read(ludoStateNotifier(widget.gameId).notifier).roll(playerId);
    _rollTimeout?.cancel();
    _rollTimeout = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_rolling) {
        setState(() {
          _rolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No response from server')),
        );
      }
    });
  }


  List<Widget> _buildAvatars() {
    final state = ref.watch(ludoStateNotifier(widget.gameId));

    final players = state.players;

    final c = state.selectedDie ?? 0;

    final alignments = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    Widget _buildDiceFace(int value, double size) {
      final path = 'assets/images/dice3d_$value.svg';
      return FutureBuilder<bool>(
        future: rootBundle.load(path).then((_) => true).catchError((_) => false),
        builder: (context, snapshot) {
          final hasAsset = snapshot.data == true;
          final Widget child = hasAsset
              ? SvgPicture.asset(path, width: size * 0.8, height: size * 0.8)
              : Text(
            '$value',
            style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.bold),
          );
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: child,
          );
        },
      );
    }

    final widgets = <Widget>[];

    for (final player in players) {
      final pid = player.playerId;
      final corner = player.cornerIndex;
      final color = player.color;

      if (corner >= alignments.length) continue;

      bool nameOnTop = (corner == 2 || corner == 3);
      bool avatarOnLeft = (corner == 1 || corner == 3);
      bool sideProfileOnLeft = !avatarOnLeft;

      Widget nameWidget = Container(
        width: 126.w,
        decoration: BoxDecoration(
          color: color ?? Colors.grey,
          borderRadius: BorderRadius.circular(2.r),
        ),
        child: Text(
          'P$pid',
          textAlign: TextAlign.center,
          style: AppTextStyles.poppinsMedium.copyWith(
            fontSize: 12.sp,
            color: Colors.black,
          ),
        ),
      );

      final diceValue = state.selectedDie ?? 0;
      Widget avatarBox = (state.turn == pid && diceValue != 0)
          ? _buildDiceFace(diceValue, 56.w)
          : Container(
        height: 56.w,
        width: 56.w,
        decoration: BoxDecoration(
          color: Colors.black54,
          border: Border.all(color: AppColors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4.r),
        ),
      );

      Widget sideProfile = Container(
        height: 46.w,
        width: 46.w,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(2.r),
        ),
        child: svgIcon(
          name: AppImages.profile,
          width: 26.w,
          height: 24.h,
          color: Colors.grey,
        ),
      );

      List<Widget> avatarRowChildren = sideProfileOnLeft
          ? [sideProfile, SizedBox(width: 4.w), avatarBox]
          : [avatarBox, SizedBox(width: 4.w), sideProfile];

      Widget avatar = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (nameOnTop) nameWidget,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: avatarRowChildren,
          ),
          if (!nameOnTop) nameWidget,
        ],
      );

      widgets.add(
        Align(
          alignment: alignments[corner],
          child: Container(
            height: 90.h,
            width: 126.w,
            margin: EdgeInsets.only(
              bottom: (corner == 0 || corner == 1) ? 8.h : 0,
              top: (corner == 2 || corner == 3) ? 8.h : 0,
            ),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: state.turn == pid ? Border.all(color: Colors.purple, width: 3) : null,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: avatar,
          ),
        ),
      );
    }

    return widgets;
  }


  Widget _winner(LudoState state) {
    if (state.winners.length == 3) {
      return Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/images/thankyou.gif"),
              const Text(
                "Thank you for playing 😙",
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              Text(
                "The Winners is: ${state.winners.map((e) => e.name.toUpperCase()).join(", ")}",
                style: const TextStyle(color: Colors.white, fontSize: 30),
                textAlign: TextAlign.center,
              ),
              const Divider(color: Colors.white),
              const Text(
                "This game made with Flutter ❤️ by Mochamad Nizwar Syafuan",
                style: TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Refresh your browser to play again",
                style: TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }



}
