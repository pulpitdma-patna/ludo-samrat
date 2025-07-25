import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/theme.dart';
import '../services/tournament_api.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';

class LeaderboardScreen extends StatefulWidget {
  final int tournamentId;
  const LeaderboardScreen({Key? key, required this.tournamentId}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _entries = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() => _loading = true);
    final data = await TournamentApi().leaderboard(widget.tournamentId);
    if (mounted) {
      setState(() {
        _entries = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Leaderboard',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final e = _entries[index] as Map;
              final prize = e['prize'];
              return ListTile(
                leading: Text('#${e['rank']}'),
                title: Text('User ${e['user_id']}'),
                trailing: prize != null ? Text(prize.toString()) : null,
              );
            },
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
