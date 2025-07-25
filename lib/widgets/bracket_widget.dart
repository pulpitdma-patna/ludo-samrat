import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

/// Displays a simple bracket tree grouped by rounds.
class BracketWidget extends StatelessWidget {
  /// List of matches maps as returned from the API.
  final List<Map<String, dynamic>> matches;

  /// Function to convert a player id to display name.
  final String Function(int?) playerName;

  const BracketWidget({
    super.key,
    required this.matches,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(child: Text('No results'));
    }

    final Map<int, List<Map<String, dynamic>>> rounds = {};
    for (final m in matches) {
      final r = m['round'] is int ? m['round'] as int : int.tryParse(m['round'].toString()) ?? 1;
      rounds.putIfAbsent(r, () => []).add(m);
    }
    final roundKeys = rounds.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in roundKeys)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Round $r',
                    style: AppTextStyles.poppinsSemiBold.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.white,
                    ),
                  ),
                  for (final m in rounds[r]!)
                    _MatchBox(
                      player1: playerName(m['player1_id']),
                      player2: playerName(m['player2_id']),
                      winner: playerName(m['winner_id']),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchBox extends StatelessWidget {
  final String player1;
  final String player2;
  final String winner;

  const _MatchBox({
    required this.player1,
    required this.player2,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$player1 vs $player2',
            style: AppTextStyles.poppinsRegular.copyWith(
              fontSize: 12.sp,
              color: AppColors.white,
            ),
          ),
          if (winner.isNotEmpty)
            Text(
              'Winner: $winner',
              style: AppTextStyles.poppinsRegular.copyWith(
                fontSize: 12.sp,
                color: AppColors.brandYellowColor,
              ),
            ),
        ],
      ),
    );
  }
}
