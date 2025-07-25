import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/theme.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_drawer.dart';
import '../models/game_result.dart';
import '../services/analytics_service.dart';
import '../services/app_preferences.dart';

class ResultsScreen extends StatefulWidget {
  final List<GameResult> results;
  const ResultsScreen({Key? key, required this.results}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _userId = 0;
  int? _rank;

  @override
  void initState() {
    super.initState();
    () async {
      final id = await AppPreferences().getUserId();
      if (!mounted) return;
      final res = widget.results.firstWhere(
        (r) => r.playerId == id,
        orElse: () => GameResult(playerId: id, rank: -1, name: null),
      );
      setState(() {
        _userId = id;
        _rank = res.rank;
      });
      if (widget.results.isNotEmpty) {
        unawaited(
            AnalyticsService.logMatchWin(0, widget.results.first.playerId));
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () {
            if (context.canPop()) {
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
              'Results',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 18.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Lottie.asset(
              'assets/animations/celebration.json',
              height: 120,
              repeat: false,
            ),
          ),
          if (_rank != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                _rank == 1 ? 'You Won!' : 'You Lost',
                style: AppTextStyles.poppinsBold.copyWith(
                  fontSize: AppTextStyles.headingLarge.fontSize!.sp,
                  color: AppColors.white,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.results.length,
              itemBuilder: (context, index) {
                final r = widget.results[index];
                return ListTile(
                  leading: Text('#${r.rank}'),
                  title: Text(r.name ?? 'Player ${r.playerId}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
