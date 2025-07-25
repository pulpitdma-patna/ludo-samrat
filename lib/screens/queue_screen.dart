import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../common_widget/app_scaffold.dart';
import '../common_widget/common_appbar.dart';
import '../services/quickplay_api.dart';
import '../providers/game_provider.dart';
import '../theme.dart';

class QueueScreen extends StatefulWidget {
  final int roomId;
  const QueueScreen({super.key, required this.roomId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final res = await QuickPlayApi().participants(widget.roomId);
    if (!mounted) return;
    if (res.isSuccess && res.data != null) {
      for (final p in res.data!) {
        final gameId = p['game_id'];
        final matchId = p['match_id'];
        if (gameId != null && matchId != null) {
          context
              .read<GameProvider>()
              .registerQuickPlay(gameId, widget.roomId, matchId);
          context.go('/game/$gameId');
          return;
        }
      }
    }
  }

  void _cancel() {
    _timer?.cancel();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: GradientAppBar(
        title: const Text('Finding Match'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: _cancel,
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
