import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/ludo_image_board/ludo_provider.dart';
import 'package:frontend/ludo_image_board/widgets/board_widget.dart';
import 'package:frontend/ludo_image_board/widgets/dice_widget.dart';
import 'package:frontend/providers/game_provider.dart';
import 'package:frontend/services/analytics_service.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/services/quickplay_api.dart';
import 'package:frontend/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';


class MainScreen extends ConsumerStatefulWidget {
  final int gameId;
  final Map<String, dynamic>? gameData;
  const MainScreen({super.key,required this.gameId,this.gameData});

  @override
  ConsumerState createState() => _MainScreen2State();
}

class _MainScreen2State extends ConsumerState<MainScreen> {

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
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ImageBoardWidget(gameId: widget.gameId,),
              // Center(child: SizedBox(width: 50, height: 50, child: ImageDiceWidget(gameId: widget.gameId,))),
            ],
          ),
          _winner(state),
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
