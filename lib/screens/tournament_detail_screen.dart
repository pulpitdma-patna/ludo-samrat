import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/common_appbar.dart';
import '../common_widget/app_scaffold.dart';
import '../widgets/app_card.dart';
import '../utils/transaction_utils.dart';
import '../utils/date_utils.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<TournamentProvider>();
    await provider.fetchTournament(widget.tournamentId);
    await provider.fetchParticipants(widget.tournamentId);
    if (provider.tournament != null && provider.tournament!['is_active'] == false) {
      await provider.fetchLeaderboard(widget.tournamentId);
    }
    final hasLeaderboard = provider.tournament != null && provider.tournament!['is_active'] == false;
    _tabController = TabController(length: hasLeaderboard ? 3 : 2, vsync: this);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tour = provider.tournament;

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
                  tabs: [
                    const Tab(text: 'Participants'),
                    const Tab(text: 'Prize Pool'),
                    if (tour!['is_active'] == false) const Tab(text: 'Leaderboard'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _participantsView(provider.participants),
                      _prizeView(tour['prize_slab'] as List<dynamic>? ?? []),
                      if (tour['is_active'] == false)
                        _leaderboardView(provider.leaderboard),
                    ],
                  ),
                ),
              ],
            ),
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
        final bookedAt = p['booked_at'];
        final subtitle = bookedAt == null
            ? ''
            : formatTimestampWithTime(bookedAt.toString());
        return ListTile(
          title: Text(
            'User ${p['user_id']}',
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

  Widget _leaderboardView(List<dynamic> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No results',
          style: AppTextStyles.poppinsRegular.copyWith(
            fontSize: AppTextStyles.body.fontSize!.sp,
            color: AppColors.white,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index] as Map;
        final prize = e['prize'];
        return ListTile(
          leading: Text(
            '#${e['rank']}',
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: AppTextStyles.body.fontSize!.sp,
              color: AppColors.white,
            ),
          ),
          title: Text(
            'User ${e['user_id']}',
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: AppTextStyles.body.fontSize!.sp,
              color: AppColors.white,
            ),
          ),
          trailing: prize != null
              ? Text(
                  prize.toString(),
                  style: AppTextStyles.poppinsRegular.copyWith(
                    fontSize: AppTextStyles.caption.fontSize!.sp,
                    color: AppColors.smallTextColor,
                  ),
                )
              : null,
        );
      },
    );
  }
}
