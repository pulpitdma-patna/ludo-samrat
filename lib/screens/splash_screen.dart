import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:flutter_svg/flutter_svg.dart' show SvgAssetLoader, svg;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/game_state_storage.dart';
import 'package:provider/provider.dart';
import '../providers/public_settings_provider.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  bool isLogin = false;
  double _progress = 0.0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    // Begin a simple animated progress bar
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_progress >= 1.0) {
        t.cancel();
      } else {
        setState(() {
          _progress += 0.05;
          if (_progress > 1.0) _progress = 1.0;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _precacheAssets();
      await _navigate();
    });
  }

  Future<void> _precacheAssets() async {
    final settings = context.read<PublicSettingsProvider>();
    await settings.refresh();

    final bundle = DefaultAssetBundle.of(context);
    try {
      await precacheImage(
        AssetImage('assets/board.png', bundle: bundle),
        context,
      );
    } catch (err) {
      log('⚠️ Failed to precache board.png: $err');
    }

    final urls = [settings.backgroundImageUrl];
    for (final url in urls) {
      if (url != null && url.isNotEmpty) {
        await precacheImage(NetworkImage(url), context);
      }
    }

    const tokens = [
      'assets/tokens/token_red.svg',
      'assets/tokens/token_blue.svg',
      'assets/tokens/token_green.svg',
      'assets/tokens/token_yellow.svg',
    ];

    for (final path in tokens) {
      final loader = SvgAssetLoader(path, assetBundle: bundle);
      await svg.cache.putIfAbsent(
        loader.cacheKey(context),
        () => loader.loadBytes(context),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final isLogin = await AppPreferences().getIsLoggedIn();
    final saved = await GameStateStorage.load();

    log('Login state: $isLogin');

    if (!mounted) return;

    if (isLogin == true) {
      final gameId = saved?['game_id'];
      if (gameId is int) {
        context.go('/game/$gameId');
      } else {
        context.go('/dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  Widget build(BuildContext context) {
    return Stack(
      children: [
        svgIcon(
          name: AppImages.bg_splash_screen,
          width: 390.w,
          height: 844.h,
        ),
        // svgIcon(
        //   name: AppImages.bg_texture_splash_screen,
        //   width: 390.w,
        //   height: 844.h,
        // ),
        Container(
          width: 390.w,
          height: 844.h,
          color: AppColors.brandPrimary.withOpacity(0.9),
        ),
        Positioned(
          bottom: 96.h,
          // right: 1.0,
          child: Column(
            children: [
              Text(
                'Ludo\nSamrat',
                textAlign: TextAlign.center,
                style: AppTextStyles.poppinsBold.copyWith(
                  color: AppColors.white,
                  fontSize: 60.sp,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 78.h),
              svgIcon(
                name: AppImages.dice_with_board,
                width: 360.w,
                height: 244.h,
              ),
              SizedBox(height: 90.h),
              SizedBox(
                width: 390.w,
                // color: Colors.red,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        stripedProgressBar(_progress),
                        SizedBox(height: 8.h),
                        Text(
                          'Loading...',
                          style: AppTextStyles.poppinsMedium.copyWith(
                            color: AppColors.brandYellowColor,
                            fontSize: 16.sp,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget stripedProgressBar(double progress) {
    const total = 12;
    final active = (progress * total).round();
    return Center(
      child: Container(
        height: 16.h,
        width: 298.w,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.20),
          border: Border.all(color: AppColors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Row(
          children: List.generate(total, (index) {
            final filled = index < active;
            return Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  height: 16.h,
                  width: 5.5.w,
                  margin: EdgeInsets.only(right: 6.w),
                  decoration: BoxDecoration(
                    color:
                        filled ? Colors.orangeAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}



class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  bool isLogin = false;
  double _progress = 0.0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_progress >= 1.0) {
        t.cancel();
      } else {
        setState(() {
          _progress += 0.05;
          if (_progress > 1.0) _progress = 1.0;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  // void _navigate() async {
  //   await Future.delayed(const Duration(seconds: 1));
  //   final token = await AuthStorage.getToken();
  //   setState(() {});
  //    isLogin = await AppPreferences().getIsLoggedIn(); // ✅ await it here
  //   print("isLogin =-=- $isLogin");
  //   setState(() {});
  //   if (
  //   // token != null ||
  //       isLogin == true) {
  //     // final enabled = await BiometricService.isEnabled();
  //     // if (enabled) {
  //     //   final ok = await BiometricService.authenticate();
  //     //   if (ok) {
  //         if (!mounted) return;
  //         context.go('/dashboard');
  //         return;
  //       // }
  //     // }
  //     await AuthStorage.clear();
  //   }
  //   if (!mounted) return;
  //   context.go('/login');
  // }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final isLogin = await AppPreferences().getIsLoggedIn();
    final saved = await GameStateStorage.load();

    log('Login state: $isLogin');

    if (!mounted) return;

    if (isLogin == true) {
      final gameId = saved?['game_id'];
      if (gameId is int) {
        context.go('/game/$gameId');
      } else {
        context.go('/dashboard');
      }
    } else {
      context.go('/login');
    }
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const widgetImage = Image(
      image: AssetImage(AppImages.logo),
      width: 223,
      height: 221,
      fit: BoxFit.cover,
    );

    const crownImage = Image(
      image: AssetImage(AppImages.yellow_crown,),
      width: 40.5,
      height: 31.5,
      color: const Color(0xFFFFD700),
    );

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final scaleX = width / 390;
    final scaleY = height / 844;

    Positioned _goldCircle(
        double left, double top, double size, double opacity, double scaleX, double scaleY) {
      return Positioned(
        left: left * scaleX,
        top: top * scaleY,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size * scaleX,
            height: size * scaleY,
            decoration: ShapeDecoration(
              color: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ),
      );
    }

    Positioned _circleCluster(
        double left,
        double top,
        double size,
        double opacity,
        List<Offset> circles,
        double scaleX,
        double scaleY) {
      return Positioned(
        left: left * scaleX,
        top: top * scaleY,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size * scaleX,
            height: size * scaleY,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: circles
                  .map((c) => _goldCircle(c.dx, c.dy, 18.98, 1.0, scaleX, scaleY))
                  .toList(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            // color: AppColors.brandPrimary,
            gradient: LinearGradient(
                colors: [
                  AppColors.primaryGradient,
                  AppColors.secondPrimaryGradient, // bottom
            ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            // border: Border.all(color: const Color(0xFFE5E7EB)
            // ),
          ),
          child: Stack(
            children: [
              _circleCluster(
                  262.56,
                  708.56,
                  94.88,
                  0.20,
                  const [
                    Offset(55.85, 49.94),
                    Offset(16.73, 41.62),
                    Offset(37.95, 37.95),
                    Offset(53.36, 61.68),
                    Offset(14.23, 53.36),
                    Offset(61.68, 22.55),
                    Offset(22.55, 14.23),
                  ],
                  scaleX,
                  scaleY),
              _circleCluster(
                  26.05,
                  26.05,
                  75.91,
                  0.20,
                  const [
                    Offset(30.84, 30.84),
                    Offset(52.19, 44.70),
                    Offset(16.97, 52.19),
                    Offset(44.70, 9.49),
                    Offset(9.49, 16.97),
                  ],
                  scaleX,
                  scaleY),
              _goldCircle(195, 621, 12, 0.60, scaleX, scaleY),
              _goldCircle(244.02, 281.33, 16, 0.50, scaleX, scaleY),
              _goldCircle(284.50, 422, 8, 0.70, scaleX, scaleY),
              _goldCircle(129.98, 633, 12, 0.60, scaleX, scaleY),
              _goldCircle(97.50, 211, 8, 0.80, scaleX, scaleY),
              const Positioned(
                  left: 174.75,
                  top: 27.75,
                  width: 40.5,
                  height: 31.5,
                  child: crownImage),
              // _goldCircle(174.75, 24, 40.5, 0.70, scaleX, scaleY),
              // Image box
              // Positioned(
              //   left: MediaQuery.of(context).size.width / 2 - 96,
              //   top: MediaQuery.of(context).size.height * 0.26,
              //   child: Container(
              //     width: 192,
              //     height: 192,
              //     decoration: BoxDecoration(
              //       color: Colors.transparent,
              //       border: Border.all(color: const Color(0xFFE5E7EB)),
              //     ),
              //   ),
              // ),
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 111.5,
                top: MediaQuery.of(context).size.height * 0.3,
                child: Container(
                  width: 223,
                  height: 221,
                  decoration: const BoxDecoration(
                    // color: AppColors.brandPrimary,
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Color(0xFF0C001A),
                    //     blurRadius: 50,
                    //     offset: Offset(0, 20),
                    //   ),
                    // ],
                  ),
                  child: widgetImage,
                ),
              ),
              // Progress bar and text
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 96,
                top: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Container(
                      width: 192,
                      height: 8,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading...',
                      style: GoogleFonts.righteous(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
