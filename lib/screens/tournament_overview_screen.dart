import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/common_appbar.dart';
import '../common_widget/app_scaffold.dart';
import '../widgets/join_tournament_dialog.dart';
import '../providers/tournament_provider.dart';
import '../providers/wallet_provider.dart';
import '../common_widget/common_toast.dart';
import '../localized_errors.dart';
import '../widgets/app_card.dart';
import '../utils/transaction_utils.dart';
import '../widgets/bracket_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../utils/date_utils.dart';


class TournamentOverviewScreen extends StatefulWidget {
  final int tournamentId;
  const TournamentOverviewScreen({Key? key, required this.tournamentId}) : super(key: key);

  @override
  State<TournamentOverviewScreen> createState() => _TournamentOverviewScreenState();
}

class _TournamentOverviewScreenState extends State<TournamentOverviewScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  Future<void> _load() async {
    await context.read<TournamentProvider>().loadOverview(widget.tournamentId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
      context.read<TournamentProvider>().loadOverview(widget.tournamentId);
    });
  }


  String _playerName(int? id) {
    if (id == null) return '';
    final provider = context.read<TournamentProvider>();
    final bracket = provider.bracket;
    final players = bracket?['participants'] as List<dynamic>? ?? [];
    final match = players.cast<Map>().firstWhere(
      (e) => e['id'] == id,
      orElse: () => {},
    );
    return match['name']?.toString() ?? 'Player $id';
  }

  Future<void> _joinTournament(Map<String, dynamic> data) async {
    final isActive = data['is_active'] == true;
    if (!isActive) return;
    final isFull = (int.tryParse(data['joined']?.toString() ?? '') ?? 0) >=
        (int.tryParse(data['seat_limit']?.toString() ?? '1') ?? 1);
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
        if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tour = provider.tournament;
    if (_tabController == null && tour != null) {
      _tabController = TabController(length: 4, vsync: this);
    }
    final joinedCount = int.tryParse(tour?['joined']?.toString() ?? '') ?? 0;
    final limit = int.tryParse(tour?['seat_limit']?.toString() ?? '0') ?? 0;
    final isFull = limit > 0 && joinedCount >= limit;
    final showJoin = tour != null &&
        tour['is_active'] == true &&
        !provider.hasJoined &&
        !isFull;

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
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
              tour?['name'] ?? 'Tournament',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: provider.isLoading || _tabController == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.smallTextColor,
                  labelStyle: AppTextStyles.poppinsMedium
                      .copyWith(fontSize: AppTextStyles.body.fontSize!.sp),
                  tabs: const [
                    Tab(text: 'Participants'),
                    Tab(text: 'Prize Pool'),
                    Tab(text: 'Schedule'),
                    Tab(text: 'Leaderboard'),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _participantsView(provider.participants),
                        _prizeView(tour?['prize_slab'] as List<dynamic>? ?? []),
                        _scheduleView(provider.bracket?['matches'] as List<dynamic>? ?? []),
                        _leaderboardView(provider.bracket?['matches'] as List<dynamic>? ?? []),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: showJoin
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: ElevatedButton(
                  onPressed: () => _joinTournament(tour!),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor: AppColors.black,
                  ),
                  child: Text(
                    'Join',
                    style: AppTextStyles.poppinsSemiBold.copyWith(fontSize: 16.sp),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _participantsView(List<dynamic> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No participants',
          style: AppTextStyles.poppinsRegular.copyWith(
            fontSize: AppTextStyles.body.fontSize!.sp,
            color: AppColors.white,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final p = data[index] as Map;
        final name = p['name']?.toString() ?? 'User ${p['user_id']}';
        final avatar = p['avatar_url']?.toString() ?? '';
        final bookedAt = p['booked_at'];
        final subtitle = bookedAt == null
            ? ''
            : formatTimestampWithTime(bookedAt.toString());
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage:
                avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(
            name,
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: AppTextStyles.body.fontSize!.sp,
              color: AppColors.white,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: AppTextStyles.caption.fontSize!.sp,
              color: AppColors.smallTextColor,
            ),
          ),
        );
      },
    );
  }

  Widget _prizeView(List<dynamic> tiers) {
    if (tiers.isEmpty) {
      return Center(
        child: Text(
          'No prize info',
          style: AppTextStyles.poppinsRegular.copyWith(
            fontSize: AppTextStyles.body.fontSize!.sp,
            color: AppColors.white,
          ),
        ),
      );
    }

    String _ordinal(int n) {
      if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
      switch (n % 10) {
        case 1:
          return '${n}st';
        case 2:
          return '${n}nd';
        case 3:
          return '${n}rd';
        default:
          return '${n}th';
      }
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index] as Map;
        final start = int.tryParse(tier['start_rank'].toString()) ?? 0;
        final end = int.tryParse(tier['end_rank'].toString()) ?? start;
        final amount = parseAmount(tier['amount']);
        final rankText = start == end
            ? _ordinal(start)
            : '${_ordinal(start)} - ${_ordinal(end)}';

        return AppCard(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          body: CardBody(
            child: Row(
              children: [
                Text(
                  rankText,
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.brandYellowColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
    );
  }

  Widget _scheduleView(List<dynamic> matches) {
    if (matches.isEmpty) {
      return const Center(child: Text('Schedule will be published once available.'));
    }
    final allStartNull = matches.every((m) {
      final map = m as Map;
      return map['scheduled_start'] == null;
    });
    if (allStartNull) {
      return const Center(child: Text('Schedule will be published once available.'));
    }

    String _fmt(String? iso) {
      if (iso == null || iso.isEmpty) return '';
      try {
        final dt = DateTime.parse(iso).toLocal();
        return DateFormat('MMM d, h:mm a').format(dt);
      } catch (_) {
        return iso;
      }
    }

    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final m = matches[index] as Map;
        final start = m['scheduled_start']?.toString();
        final end = m['scheduled_end']?.toString();
        final p1 = _playerName(m['player1_id']);
        final p2 = _playerName(m['player2_id']);
        final startStr = _fmt(start);
        final endStr = _fmt(end);
        final subtitle = (startStr.isEmpty && endStr.isEmpty)
            ? 'TBD'
            : '$startStr - $endStr';
        return ListTile(
          title: Text('$p1 vs $p2'),
          subtitle: Text(subtitle),
        );
      },
    );
  }

  Widget _leaderboardView(List<dynamic> matches) {
    return BracketWidget(
      matches: matches.cast<Map<String, dynamic>>(),
      playerName: _playerName,
    );
  }
}
