import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_toast.dart';
import 'package:frontend/localized_errors.dart';
import 'package:frontend/ludo_image_board/main_screen.dart';
import 'package:frontend/providers/quickplay_provider.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:provider/provider.dart';
import '../common_widget/app_scaffold.dart';
import '../services/tutorial_storage.dart';
import '../widgets/tutorial_overlay.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_box.dart';
import '../providers/wallet_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_card.dart';
import '../widgets/quick_play_dialog.dart';
import '../providers/public_settings_provider.dart';
import '../widgets/price_filter_modal.dart';

class MatchFindingSheet extends StatefulWidget {
  final VoidCallback onCancel;

  const MatchFindingSheet({super.key, required this.onCancel});

  @override
  State<MatchFindingSheet> createState() => _MatchFindingSheetState();
}

class _MatchFindingSheetState extends State<MatchFindingSheet> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        CommonToast.show("No match found. Try again later.");
        widget.onCancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: AppGradients.blueVertical,
            borderRadius: BorderRadius.circular(20.r),
            border:
                Border.all(color: AppColors.brandYellowColor.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.brandYellowColor,
                strokeWidth: 4.w,
              ),
              SizedBox(height: 16.h),
              Text(
                "Finding a match…",
                style: AppTextStyles.poppinsMedium.copyWith(
                  fontSize: 16.sp,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "This might take a few seconds.",
                style: AppTextStyles.poppinsRegular.copyWith(
                  fontSize: 13.sp,
                  color: Colors.white60,
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  widget.onCancel();
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showMatchFindingSheet(BuildContext context,
    {required VoidCallback onCancel}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => MatchFindingSheet(onCancel: onCancel),
  );
}

class QuickPlayScreen extends StatefulWidget {
  const QuickPlayScreen({super.key});

  @override
  State<QuickPlayScreen> createState() => _QuickPlayScreenState();
}

class _QuickPlayScreenState extends State<QuickPlayScreen> {


  bool _showTutorial = false;

  void _checkTutorial() async {
    final seen = await TutorialStorage.hasSeenFeature('quickplay');
    if (!seen) setState(() => _showTutorial = true);
  }

  void _dismissTutorial() async {
    await TutorialStorage.setFeatureSeen('quickplay');
    setState(() => _showTutorial = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
      context.read<QuickPlayProvider>().getRooms();
      context.read<PublicSettingsProvider>().refresh();
    });
    _checkTutorial();
  }

  Future<void> _refresh() async {
    await context.read<QuickPlayProvider>().getRooms();
  }

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<QuickPlayProvider>();
    final tournaments = provider.allRooms;

    return AppScaffold(
      isLoading: provider.isLoading,
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
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
            Text("Quick Play",textAlign: TextAlign.start,
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        suffixIcon: GestureDetector(
          onTap: () async {
            final range = await showPriceFilterModal(context);
            if (range != null) {
              await context.read<QuickPlayProvider>().getRooms(
                    minStake: range.min,
                    maxStake: range.max,
                  );
            }
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: Center(
              child: svgIcon(
                name: AppImages.filter,
                width: 16.w,
                height: 16.h,
                color: AppColors.brandYellowColor,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              _allTournamentList(
                  tournamentsList: tournaments
              ),
              // _buildTournamentCard(
              //   title: "Pro League",
              //   subtitle: "8 Players • Expert Level",
              //   entry: "₹100",
              //   joined: 67,
              //   total: 100,
              //   progressColor: Colors.purple,
              //   prize: "₹10,000",
              //   firstPrize: "₹5,000",
              // ),
              // _buildTournamentCard(
              //   title: "Beginner’s Luck",
              //   subtitle: "4 Players • New Players",
              //   entry: "Free",
              //   joined: 234,
              //   total: 250,
              //   progressColor: Colors.green,
              //   prize: "₹500",
              //   firstPrize: "₹200",
              // ),
              SizedBox(height: 20.h), // for bottom nav spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionHeader({
    required String title,
    required bool showViewAll,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal.w,
        vertical: 0.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 16.sp,
              color: AppColors.white,
            ),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  svgIcon(
                    name: AppImages.filter,
                    width: 14.w,
                    height: 14.h,
                    color: AppColors.brandYellowColor,
                  ),
                  SizedBox(
                    width: 2.w,
                  ),
                  Text(
                    "Filter",
                    style: AppTextStyles.poppinsMedium.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.brandYellowColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }



  Widget _allTournamentList({required List<dynamic> tournamentsList}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal.w),
          child: Text(
            'Quick Play',
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 16.sp,
              color: AppColors.white,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          itemBuilder: (context, index) {
            return _buildQuickPlayCard(
                data:tournamentsList[index]
            );
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: 12.h,);
          },
          shrinkWrap: true,
          itemCount: tournamentsList.length,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ],
    );
  }

  Widget _buildQuickPlayCard({
    required Map<String, dynamic> data,
  }) {
    final participants =
        int.tryParse(data['participant_count']?.toString() ?? '0') ?? 0;
    final playerCount = int.tryParse(data['player_count']?.toString() ?? '0') ?? 0;
    final maxTurns = int.tryParse(data['max_turns']?.toString() ?? '');
    final stake = (data['stake'] ?? 0).toDouble();
    final pot = (data['pot'] ?? 0).toDouble();
    final discount = double.tryParse(data['discount']?.toString() ?? '0') ?? 0.0;
    final id = int.tryParse(data['id']?.toString() ?? '') ?? 0;
    final fee = stake * (1 - discount / 100);
    final bracketInfo = '$playerCount players 1 winner';

    Future<void> _join(bool ai) async {
      final wallet = context.read<WalletProvider>().totalAmount;

      if (wallet < fee) {
        final need = fee - wallet;
        context.push('/deposit?amount=${need.toStringAsFixed(0)}');
        return;
      }

      final confirm = await showQuickPlayDialog(context, fee: fee) ?? false;
      if (!confirm) return;

      if (!ai) {
        await showMatchFindingSheet(
          context,
          onCancel: () {
            // You could add cancellation logic if needed
          },
        );
      }

        final result =
            await context.read<QuickPlayProvider>().joinRoom(id, context, ai: ai);

        if (result.isSuccess) {
          await context.read<WalletProvider>().load();
          final gameId = result.data?['game_id'];
          final matchId = result.data?['match_id'];
          if (gameId != null && matchId != null) {
            context.read<GameProvider>().registerQuickPlay(gameId, id, matchId);
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return MainScreen(gameId: gameId,gameData: data,);
              },));
            }
            // if (mounted) {
            //   context.push(
            //     '/game/$gameId',
            //     extra: data,
            //   );
            // }
          } else {
            if (mounted) context.push('/queue?roomId=$id');
          }
        } else {
          final msg = localizeError(result.code, result.error!);
          CommonToast.error(msg);
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameCard(
          title: Row(
            children: [
              svgIcon(
                name: AppImages.people,
                width: 16.w,
                height: 16.h,
                color: AppColors.brandYellowColor,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  '$participants',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          entryFee: stake,
          prize: pot,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          bracketInfo: bracketInfo,
          secondaryInfo: maxTurns != null ? 'Max Turns: $maxTurns' : 'No Turn Limit',
          extraInfo: discount > 0
              ? '₹${stake.toStringAsFixed(0)} → ₹${fee.toStringAsFixed(0)} (${discount.toStringAsFixed(0)}% Off)'
              : null,
          joined: null,
          seatLimit: null,
          progress: null,
          actionText: 'Play',
          onAction: () => _join(false),
          gradient: AppGradients.blueVertical,
          border: Border.all(color: AppColors.brandYellowColor.withOpacity(0.3)),
        ),
        SizedBox(height: 8.h),
        if (context.watch<PublicSettingsProvider>().aiPlayEnabled)
          ElevatedButton.icon(
            // onPressed: () {
            //    Navigator.push(context, MaterialPageRoute(builder: (context) {
            //    return MainScreen(gameId: 1,gameData: data,);
            //     },));
            // },
            onPressed: () => _join(true),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 8.h),
            ),
            icon: const Icon(Icons.smart_toy),
            label: const Text('Play vs AI'),
          ),
      ],
    );
  }
}
