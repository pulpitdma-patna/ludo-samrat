import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/ludo_image_board/ludo_provider.dart';
import 'package:frontend/ludo_image_board/widgets/board_widget.dart';
import 'package:frontend/ludo_image_board/widgets/dice_widget.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:frontend/widgets/app_drawer.dart';
import 'package:provider/provider.dart';

import '../app_images.dart' show AppImages;

class MainScreen extends StatefulWidget {
  final int gameId;
  final Map<String, dynamic>? gameData;
  const MainScreen({super.key,required this.gameId,this.gameData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  Map<String,dynamic> _gamData = {};
  bool _isThreeDices = false;

  @override
  void initState() {
    context.read<LudoProvider>().startGame();
    if(widget.gameData != null){
      debugPrint("Data -=--${widget.gameData}");
      _gamData = widget.gameData!;
      if(_gamData['engine'] == 'three_dice'){
        _isThreeDices = true;
      }
    }
    super.initState();
  }

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundGradient: AppGradients.blueHorizontal,
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          // onTap: () async {
          //   final shouldPop = await _onWillPop();
          //   if (shouldPop && mounted && context.canPop()) {
          //     context.pop();
          //   }
          // },
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
                 Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ImageBoardWidget(gameId: widget.gameId,isThreeDices: _isThreeDices,),
                    // Center(child: SizedBox( height: 50,child: ImageDiceWidget(gameId: widget.gameId,isThreeDices: _isThreeDices,))),
                  ],
                ),
                ... buildAvatars(_isThreeDices ? {171:0,172:3} : {171:0,172:1,173:2,174:3,}),
                 Consumer<LudoProvider>(
                  builder: (context, value, child) => value.winners.length == 3
                      ? Container(
                          color: Colors.black.withOpacity(0.8),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset("assets/images/thankyou.gif"),
                                const Text("Thank you for playing 😙", style: TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
                                Text("The Winners is: ${value.winners.map((e) => e.name.toUpperCase()).join(", ")}", style: const TextStyle(color: Colors.white, fontSize: 30), textAlign: TextAlign.center),
                                const Divider(color: Colors.white),
                                const Text("This game made with Flutter ❤️ by Mochamad Nizwar Syafuan", style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                const Text("Refresh your browser to play again", style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(child: SizedBox( height: 50,child: ImageDiceWidget(gameId: widget.gameId,isThreeDices: _isThreeDices,))),
          ),
        ],
      ),
    );
  }

  List<Widget> buildAvatars(Map<int, int> corners) {
    // final state = ref.watch(gameStateProvider(widget.gameId));

    final alignments = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    final cornerColor = [
      Colors.green,
      Colors.yellow,
      Colors.red,
      Colors.blue,
    ];

    // Helper to render dice face (SVG or fallback text)
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
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: child,
          );
        },
      );
    }

    final widgets = <Widget>[];

    corners.forEach((pid, corner) {
      if (corner < alignments.length) {
        // Layout rules
        bool nameOnTop = (corner == 2 || corner == 3); // bottom corners
        bool avatarOnLeft = (corner == 1 || corner == 3); // topRight & bottomRight
        bool sideProfileOnLeft = !avatarOnLeft;

        // Name container
        Widget nameWidget = Container(
          width: 126.w,
          decoration: BoxDecoration(
            color: cornerColor[corner],
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

        // Show selected dice in 56x56 container
        // final diceValue = state.selectedDie ?? 0;
        Widget avatarBox =  Container(
          height: 56.w,
          width: 56.w,
          decoration: BoxDecoration(
            // color: Colors.black54,
            border: Border.all(color: AppColors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Image.asset(
            "assets/images/dice/${1}.png",
            // width: 40,
            // height: 40,
            fit: BoxFit.cover,
          ),
        );

        // Profile icon container
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

        // Arrange avatar row
        List<Widget> avatarRowChildren = sideProfileOnLeft
            ? [sideProfile, SizedBox(width: 4.w), avatarBox]
            : [avatarBox, SizedBox(width: 4.w), sideProfile];

        // Assemble avatar column
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

        // Final aligned container
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
                border: null,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: avatar,
            ),
          ),
        );
      }
    });

    return widgets;
  }

}







// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:frontend/common_widget/app_scaffold.dart';
// import 'package:frontend/common_widget/common_appbar.dart';
// import 'package:frontend/constants.dart';
// import 'package:frontend/ludo_image_board/ludo_provider.dart';
// import 'package:frontend/ludo_image_board/ludo_state_notifier.dart';
// import 'package:frontend/ludo_image_board/widgets/board_widget.dart';
// import 'package:frontend/ludo_image_board/widgets/dice_widget.dart';
// import 'package:frontend/providers/game_provider.dart';
// import 'package:frontend/services/analytics_service.dart';
// import 'package:frontend/services/app_preferences.dart';
// import 'package:frontend/services/quickplay_api.dart';
// import 'package:frontend/theme.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../widgets/app_drawer.dart';
//
//
// class MainScreen extends ConsumerStatefulWidget {
//   final int gameId;
//   final Map<String, dynamic>? gameData;
//   const MainScreen({super.key,required this.gameId,this.gameData});
//
//   @override
//   ConsumerState createState() => _MainScreen2State();
// }
//
// class _MainScreen2State extends ConsumerState<MainScreen> {
//
//   @override
//   Widget build(BuildContext context) {
//
//     final state = ref.watch(ludoStateNotifier(widget.gameId));
//
//     return AppScaffold(
//       backgroundGradient: AppGradients.blueHorizontal,
//       drawer: const AppDrawer(),
//       appBar: GradientAppBar(
//         leading: InkWell(
//           onTap: () async {
//             final shouldPop = await _onWillPop();
//             if (shouldPop && mounted && context.canPop()) {
//               context.pop();
//             }
//           },
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
//       body: Stack(
//         alignment: Alignment.center,
//         children: [
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               ImageBoardWidget(gameId: widget.gameId,),
//               // Center(child: SizedBox(width: 50, height: 50, child: ImageDiceWidget(gameId: widget.gameId,))),
//             ],
//           ),
//           _winner(state),
//     ],
//       ),
//     );
//   }
//
//   Future<bool> _onWillPop() async {
//     final shouldQuit = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             const Icon(Icons.warning_amber_rounded, color: Colors.red),
//             SizedBox(width: 8.w),
//             const Text('Quit Match?'),
//           ],
//         ),
//         content: const Text(
//           'Are you sure you want to quit the match?',
//           style: TextStyle(fontSize: 16),
//         ),
//         actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         actionsAlignment: MainAxisAlignment.spaceBetween,
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(false),
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.grey[700],
//             ),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(ctx).pop(true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.redAccent,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Quit'),
//           ),
//         ],
//       ),
//     );
//
//     if (shouldQuit == true) {
//       final roomId = context.read<GameProvider>().roomIdForGame(widget.gameId);
//       final matchId = context.read<GameProvider>().matchIdForGame(widget.gameId);
//
//       if (roomId != null && matchId != null) {
//         final partsRes = await QuickPlayApi().participants(roomId);
//         if (partsRes.isSuccess && partsRes.data != null) {
//           final myId = await AppPreferences().getUserId();
//           int? winner;
//           for (final p in partsRes.data!) {
//             final uid = int.tryParse(p['user_id']?.toString() ?? '');
//             if (uid != null && uid != myId) {
//               winner = uid;
//               break;
//             }
//           }
//           if (winner != null) {
//             await context.read<GameProvider>().endQuickPlay(
//               roomId,
//               matchId,
//               winner,
//               context,
//             );
//           }
//         }
//       }
//
//       unawaited(AnalyticsService.logGameEnd(widget.gameId));
//       // ref.invalidate(gameStateProvider(widget.gameId));
//
//       if (context.canPop()) {
//         context.pop();
//       } else {
//         context.go('/dashboard');
//       }
//       return false;
//     }
//
//     return false;
//   }
//
//   Widget _winner(LudoState state) {
//     if (state.winners.length == 3) {
//       return Container(
//         color: Colors.black.withOpacity(0.8),
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.asset("assets/images/thankyou.gif"),
//               const Text(
//                 "Thank you for playing 😙",
//                 style: TextStyle(color: Colors.white, fontSize: 20),
//                 textAlign: TextAlign.center,
//               ),
//               Text(
//                 "The Winners is: ${state.winners.map((e) => e.name.toUpperCase()).join(", ")}",
//                 style: const TextStyle(color: Colors.white, fontSize: 30),
//                 textAlign: TextAlign.center,
//               ),
//               const Divider(color: Colors.white),
//               const Text(
//                 "This game made with Flutter ❤️ by Mochamad Nizwar Syafuan",
//                 style: TextStyle(color: Colors.white, fontSize: 15),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Refresh your browser to play again",
//                 style: TextStyle(color: Colors.white, fontSize: 10),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
//     } else {
//       return const SizedBox.shrink();
//     }
//   }
//
//
//
// }
