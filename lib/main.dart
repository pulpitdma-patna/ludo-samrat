import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/ludo_image_board/ludo_provider.dart';
import 'package:frontend/providers/kyc_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/quickplay_provider.dart';
import 'package:frontend/providers/referral_provider.dart';
import 'package:frontend/screens/referral_screen.dart';
import 'package:frontend/screens/withdraw_screen.dart';
import 'package:frontend/screens/deposit_screen.dart';
import 'package:frontend/screens/transfer_screen.dart';
import 'package:toastification/toastification.dart';
import 'providers/home_provider.dart';
import 'services/app_preferences.dart';
import 'theme.dart';
import 'services/theme_storage.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/tournament_list_screen.dart';
import 'screens/create_tournament_screen.dart';
import 'screens/game_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/results_screen.dart';
import 'models/game_result.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/tournament_detail_screen.dart';
import 'screens/tournament_overview_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/quick_play_screen.dart';
import 'screens/queue_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/kyc_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/board_preferences_screen.dart';
import 'screens/not_found_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/public_settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/analytics_service.dart';

final FlutterLocalNotificationsPlugin localNotifications =
FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<ThemeMode> themeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);
GoRouter? router;
String? _pendingRoute;

void _handleNotificationTap(String? payload) {
  if (payload == null || payload.isEmpty) return;
  // Notifications may send routes without a leading slash (e.g. "game/123").
  // Normalise the route so that GoRouter can recognise it.
  final route = payload.startsWith('/') ? payload : '/$payload';
  final r = router;
  if (r != null) {
    r.go(route);
  } else {
    _pendingRoute = route;
  }
}

Future<void> main() async {
  await ScreenUtil.ensureScreenSize();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppPreferences.init();
  // Initialize Firebase Analytics
  AnalyticsService.analytics;
  const androidChannel = AndroidNotificationChannel(
    'default_channel',
    'Default',
    importance: Importance.high,
  );
  await localNotifications
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await localNotifications.initialize(initSettings,
      onDidReceiveNotificationResponse: (resp) {
        _handleNotificationTap(resp.payload);
      });

  FirebaseMessaging.onMessage.listen((m) {
    final notification = m.notification;
    if (notification != null) {
      final details = NotificationDetails(
          android: AndroidNotificationDetails(androidChannel.id, androidChannel.name,
              channelDescription: 'Default notifications',
              importance: Importance.high,
              priority: Priority.high));
      localNotifications.show(notification.hashCode, notification.title,
          notification.body, details,
          payload: m.data['route']);
    }
  });

  FirebaseMessaging.onMessageOpenedApp
      .listen((m) => _handleNotificationTap(m.data['route']));

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  final initialLocation =
  initialMessage != null && initialMessage.data['route'] != null
      ? initialMessage.data['route'] as String
      : '/splash';
  themeNotifier.value = await ThemeStorage.getThemeMode();

  router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/login', builder: (c, s) => LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/withdraw', builder: (c, s) => const WithdrawScreen()),
      GoRoute(path: '/deposit', builder: (c, s) {
        final amt = double.tryParse(s.uri.queryParameters['amount'] ?? '');
        return DepositScreen(amount: amt);
      }),
      GoRoute(path: '/transfer', builder: (c, s) => const TransferScreen()),
      GoRoute(
          path: '/verify/:phone',
          builder: (c, s) => OtpVerificationScreen(
              phoneNumber: Uri.decodeComponent(s.pathParameters['phone']!))),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (c, s) {
          final idx =
              s.extra as int? ?? int.tryParse(s.uri.queryParameters['tab'] ?? '0') ?? 0;
          final tId = int.tryParse(s.uri.queryParameters['tournament'] ?? '');
          return DashboardScreen(initialIndex: idx, tournamentId: tId);
        },
        redirect: (ctx, state) {
          final auth = ctx.read<AuthProvider>();

          if (auth.isLoading) return null;

          return auth.isAuthenticated ? null : '/login';
        },
      ),
      GoRoute(
          path: '/tournaments',
          builder: (c, s) => const TournamentListScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/create-tournament',
          builder: (c, s) => const CreateTournamentScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/wallet',
          builder: (c, s) => const WalletScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/wallet/transactions',
          builder: (c, s) => const TransactionHistoryScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/profile',
          builder: (c, s) => ProfileScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/profile/edit',
          builder: (c, s) => const ProfileEditScreen(),
          redirect: (ctx, state) =>
              ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/kyc',
          builder: (c, s) => const KycScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/friends',
          builder: (c, s) => FriendsScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/matches',
          builder: (c, s) => MatchesScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/quickplay',
          builder: (c, s) => const QuickPlayScreen(),
          redirect: (ctx, state) =>
              ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/queue',
          builder: (c, s) {
            final id = int.tryParse(s.uri.queryParameters['roomId'] ?? '');
            if (id == null) return const NotFoundScreen();
            return QueueScreen(roomId: id);
          },
          redirect: (ctx, state) =>
              ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final gameId = int.parse(state.pathParameters['id']!);
          final gameData = state.extra as Map<String, dynamic>?;

          return GameScreen(
            gameId: gameId,
            gameData: gameData,
          );
        },
        redirect: (context, state) =>
        context.read<AuthProvider>().isAuthenticated ? null : '/login',
      ),
      GoRoute(
        path: '/tournament/:id',
        builder: (c, s) => TournamentOverviewScreen(
            tournamentId: int.parse(s.pathParameters['id']!)),
        redirect: (ctx, state) =>
            ctx.read<AuthProvider>().isAuthenticated ? null : '/login',
      ),
      GoRoute(
        path: '/tournament/:id/leaderboard',
        builder: (c, s) => LeaderboardScreen(
            tournamentId: int.parse(s.pathParameters['id']!)),
        redirect: (ctx, state) =>
        ctx.read<AuthProvider>().isAuthenticated ? null : '/login',
      ),
      GoRoute(
        path: '/results',
        builder: (c, s) => ResultsScreen(results: (s.extra as List<GameResult>)),
        redirect: (ctx, state) =>
        ctx.read<AuthProvider>().isAuthenticated ? null : '/login',
      ),
      GoRoute(
          path: '/referral',
          builder: (c, s) => const ReferralScreen(),
          redirect: (ctx, state) =>
          ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/settings',
          builder: (c, s) => const SettingsScreen(),
          redirect: (ctx, state) =>
              ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
      GoRoute(
          path: '/board-preferences',
          builder: (c, s) => const BoardPreferencesScreen(),
          redirect: (ctx, state) =>
              ctx.read<AuthProvider>().isAuthenticated ? null : '/login'),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );

  if (_pendingRoute != null) {
    router!.go(_pendingRoute!);
    _pendingRoute = null;
  }

  runApp(riverpod.ProviderScope(
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => QuickPlayProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(create: (_) => PublicSettingsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => LudoProvider()),
      ],
      child: MyApp(router: router!),

    ),
  ));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return ScreenUtilInit(
            designSize: Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            child: ToastificationWrapper(
              config: const ToastificationConfig(
                // margin: EdgeInsets.fromLTRB(0, 16, 0, 110),
                alignment: Alignment.center,
                itemWidth: 1080,
                animationDuration: Duration(milliseconds: 500),
              ),
              child: MaterialApp.router(
                routerConfig: router,
                debugShowCheckedModeBanner: false,
                title: 'Ludo Samrat',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: mode,
              ),
            ));
      },
    );
  }
}