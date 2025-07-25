import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_toast.dart';
import 'package:frontend/localized_errors.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../common_widget/app_scaffold.dart';
import '../providers/tournament_provider.dart';
import '../services/tutorial_storage.dart';
import '../widgets/tutorial_overlay.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_drawer.dart';
import '../providers/wallet_provider.dart';
import '../widgets/game_card.dart';
import '../widgets/join_tournament_dialog.dart';
import '../widgets/price_filter_modal.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {

  bool _showTutorial = false;

  void _checkTutorial() async {
    final seen = await TutorialStorage.hasSeenFeature('tournaments');
    if (!seen) setState(() => _showTutorial = true);
  }

  void _dismissTutorial() async {
    await TutorialStorage.setFeatureSeen('tournaments');
    setState(() => _showTutorial = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
      context.read<TournamentProvider>().getTournaments();
      context.read<TournamentProvider>().getMyStats();
    });
    _checkTutorial();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<TournamentProvider>().getTournaments(),
      context.read<TournamentProvider>().getMyStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<TournamentProvider>();
    final tournaments = provider.allTournaments;

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
            Expanded(
              child: Text(
                "Tournaments",
                textAlign: TextAlign.start,
                style: AppTextStyles.poppinsSemiBold.copyWith(
                  fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        suffixIcon: GestureDetector(
          onTap: () async {
            final range = await showPriceFilterModal(context);
            if (range != null) {
              context.read<TournamentProvider>().setMinFee(range.min);
              context.read<TournamentProvider>().setMaxFee(range.max);
              await context.read<TournamentProvider>().getTournaments();
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
                _allTournamentList(
                  tournamentsList: tournaments
                ),
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
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 16.sp,
                color: AppColors.white,
              ),
              overflow: TextOverflow.ellipsis,
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _allTournamentList({required List<dynamic> tournamentsList}) {
    if(tournamentsList.isNotEmpty){
        return Column(
        children: [
          ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemBuilder: (context, index) {
              return _buildTournamentCard(
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Text(
          "No tournaments available",
          style: AppTextStyles.poppinsRegular.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14.sp,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

  }
  Widget _buildTournamentCard({
    required Map<String, dynamic> data,
  }) {
    final joined = int.tryParse(data['joined']?.toString() ?? '') ?? 0;
    final limit = int.tryParse(data['seat_limit']?.toString() ?? '') ?? 1;
    final progress = (limit > 0) ? (joined / limit).clamp(0.0, 1.0) : 0.0;
    final discount =
        double.tryParse(data['discount']?.toString() ?? '0') ?? 0.0;
    final playerCount = int.tryParse(data['player_count']?.toString() ?? '0') ?? 0;
    final isActive = data['is_active'] == true;
    final startIso = data['start_time']?.toString();
    final bracketInfo = '$playerCount players 1 winner';
    String? startTime;
    if (startIso != null && startIso.isNotEmpty) {
      try {
        final dt = DateTime.parse(startIso).toLocal();
        startTime = DateFormat('MMM d, h:mm a').format(dt);
      } catch (_) {}
    }
    final isFull = joined >= limit;
    final hasJoined = data['has_joined'] == true;
    final prizeSlab = data['prize_slab'];
    double prize = 0.0;
    if (prizeSlab is List && prizeSlab.isNotEmpty) {
      final first = prizeSlab.first;
      if (first is Map && first['amount'] != null) {
        final amount = first['amount'];
        if (amount is num) {
          prize = amount.toDouble();
        } else {
          prize = double.tryParse(amount.toString()) ?? 0.0;
        }
      }
    }

    return GameCard(
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
              '$joined',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      entryFee: (data['join_fee'] ?? 0).toDouble(),
      prize: prize,
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
      joined: joined,
      seatLimit: limit,
      progress: progress,
      bracketInfo: bracketInfo,
      startTime: startTime,
      extraInfo:
          discount > 0 ? 'Discount ${discount.toStringAsFixed(0)}%' : 'Prize Pool',
      statusText: isActive ? 'Live' : 'Completed',
      statusColor: isActive ? Colors.green : Colors.grey,
      actionText: !isActive
          ? 'View'
          : hasJoined
              ? 'View'
              : isFull
                  ? 'Full'
                  : 'Join',
      actionEnabled: hasJoined || (isActive && !isFull && !hasJoined),
      onAction: () async {
        if (hasJoined || !isActive) {
          context.push('/tournament/${data['id']}');
          return;
        }
        if (isFull) return;

        final wallet = context.read<WalletProvider>().totalAmount;
        final fee = (data['join_fee'] ?? 0).toDouble();
          if (wallet >= fee) {
            final confirm =
                await showJoinTournamentDialog(context, fee: fee) ?? false;
          if (!confirm) return;

          final result = await context
              .read<TournamentProvider>()
              .join(data['id'], context);
          if (result.isSuccess) {
            await context.read<WalletProvider>().load();
            final gameId = result.data?['game_id'] as int?;
            if (gameId != null) {
              context.push('/game/$gameId');
            } else {
              context.push('/tournament/${data['id']}');
            }
          } else {
            final msg = localizeError(result.code, result.error!);
            CommonToast.error(msg);
          }
        } else {
          final need = fee - wallet;
          context.push('/deposit?amount=${need.toStringAsFixed(0)}');
        }
      },
      gradient: AppGradients.blueVertical,
      border: Border.all(color: AppColors.brandYellowColor.withOpacity(0.3)),
    );
  }

}
