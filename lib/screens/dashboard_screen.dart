import 'package:flutter/material.dart';
import 'package:frontend/common_widget/app_scaffold.dart';
import 'package:frontend/ludo_image_board/main_screen.dart';
import 'package:frontend/screens/quick_play_screen.dart';

import 'bottom_nav_bar.dart';
import 'home_screen.dart';
import 'tournament_list_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'tournament_overview_screen.dart';
import '../widgets/tutorial_overlay.dart';
import '../services/tutorial_storage.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  final List<Widget>? screens;
  final int? tournamentId;
  const DashboardScreen({Key? key, this.initialIndex = 0, this.screens, this.tournamentId})
      : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;
  bool _showTutorial = false;

  void _checkTutorial() async {
    final seen = await TutorialStorage.hasSeenTutorial();
    if (!seen) {
      setState(() => _showTutorial = true);
    }
  }

  void _dismissTutorial() async {
    await TutorialStorage.setSeen();
    setState(() => _showTutorial = false);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = widget.screens ?? [
      const HomeScreen(),
      const QuickPlayScreen(),
      // MainScreen(gameId: 1,gameData: {},),
      const TournamentListScreen(),
      const WalletScreen(),
      ProfileScreen(),
    ];
    _checkTutorial();
  }

  void _navigate(int index) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated && index != 0) {
      context.go('/login');
      return;
    }
    setState(() => _currentIndex = index);
    context.go('/dashboard?tab=$index');
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.tournamentId != null
        ? TournamentOverviewScreen(tournamentId: widget.tournamentId!)
        : _screens.elementAt(_currentIndex);
    return AppScaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          body,
          if (_showTutorial) TutorialOverlay(onDismiss: _dismissTutorial),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _navigate,
      ),
    );
  }
}
