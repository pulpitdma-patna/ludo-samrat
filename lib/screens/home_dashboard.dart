import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_toast.dart';
import 'package:frontend/localized_errors.dart';
import 'package:frontend/providers/home_provider.dart';
import 'package:frontend/utils/svg_icon.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/tournament_provider.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme.dart';
import '../constants.dart';
import '../common_widget/common_button.dart';
import '../providers/wallet_provider.dart';
import '../providers/public_settings_provider.dart';
import '../services/app_preferences.dart';
import '../utils/transaction_utils.dart';
import '../widgets/join_tournament_dialog.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  /// Tracks the current banner index in the [CarouselSlider].
  int _bannerIndex = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load();
      context.read<HomeProvider>().load();
      context.read<TournamentProvider>().load();
      context.read<GameProvider>().loadRecentGames();
      context.read<ProfileProvider>().getProfile();
    });
  }

  Future<void> _playAi() async {
    final res =
        await context.read<GameProvider>().queueGame(ai: true, ctx: context);
    if (res.isSuccess) {
      final id = res.data;
      if (id != null) {
        if (mounted) context.push('/game/$id');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to queue, waiting for opponent')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error!)));
    }
  }

  Future<void> _joinGame() async {
    if (!context.read<AuthProvider>().isAuthenticated) {
      context.go('/login');
      return;
    }
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Game'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Game ID'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          CommonButton(
            width: 80.w,
            onPressed: () async {
              final id = int.tryParse(controller.text);
              if (id == null) return;
              final res =
                  await context.read<GameProvider>().joinGame(id, ctx: context);
              Navigator.pop(ctx);
              if (res.isSuccess) {
                context.push('/game/$id');
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(res.error!)));
              }
            },
            btnChild: Text(
              'Join',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 14.sp,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<TournamentProvider>().load(),
      context.read<GameProvider>().loadRecentGames(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           bannerSlider(),
          // _welcomeCard(),
          _gameModes(),
          _liveTournaments(),
          _recentGames(),

       /*   // Image.asset('assets/logo.png', height: 120),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (!context.read<AuthProvider>().isAuthenticated) {
                    context.go('/login');
                  } else {
                    context.go('/quickplay');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24),
                ),
                child: Text(
                  'Play Now',
                    style: AppTextStyles.poppinsSemiBold.copyWith(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            children: [
              if (context.watch<PublicSettingsProvider>().aiPlayEnabled)
                ElevatedButton(
                  onPressed: _playAi,
                  child: const Text('Play vs AI'),
                ),
              ElevatedButton(
                onPressed: _joinGame,
                child: const Text('Join Game'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('Live Tournaments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...tournaments.map((t) {
            final active = t['is_active'] == true;
            return ListTile(
              title: Text(t['name'] ?? 'Tournament'),
              trailing: active
                  ? ElevatedButton(
                      onPressed: () async {
                        final ok = await context
                            .read<TournamentProvider>()
                            .join(t['id']);
                        if (ok) context.push('/tournament/${t['id']}');
                      },
                      child: const Text('Join'),
                    )
                  : TextButton(
                      onPressed: () =>
                          context.push('/tournament/${t['id']}/leaderboard'),
                      child: const Text('Results'),
                    ),
            );
          }),
          const SizedBox(height: 30),
          Text('Recent Games', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...matches.map((m) => ListTile(
                title: Text('Match ${m['match_id']}'),
                subtitle: Text(m['result'].toString()),
              )),*/
        ],
      ),
    );
  }


  Widget bannerSlider() {
    final homeProvider = context.watch<HomeProvider>();
    final banners = homeProvider.bannerList;
    final isLoading = homeProvider.isLoading;

    final screenSize = MediaQuery.of(context).size;
    final sliderHeight = screenSize.width * 0.45;

    if (isLoading) {
      return SizedBox(
        height: sliderHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (banners.isEmpty) {
      return _welcomeCard();
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: sliderHeight,
            autoPlay: true,
            viewportFraction: 1,
            enlargeCenterPage: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            onPageChanged: (index, reason) {
              setState(() {
                _bannerIndex = index;
              });
            },
          ),
          items: banners.map((banner) {
            return _bannerCard(data: banner);
          }).toList(),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isActive = _bannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: isActive ? 12.w : 8.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: isActive ? AppColors.brandYellowColor : Colors.grey,
                borderRadius: BorderRadius.circular(4.r),
              ),
            );
          }),
        ),
      ],
    );
  }


  Widget _bannerCard({required Map<String,dynamic> data}) {
    final imageUrl = data['file_path'] ?? data['image_url'];
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('Banner missing file_path and image_url: $data');
    }
    return GestureDetector(
      onTap: () {

      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.image_not_supported)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      // padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Decorative circles (bottom right)
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -30,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main content
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w,vertical: 19.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                    style: AppTextStyles.poppinsBold.copyWith(
                      fontSize: 20.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to play and win amazing prizes?',
                    style: AppTextStyles.poppinsRegular.copyWith(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ),
                const SizedBox(height: 16),
                  CommonButton(
                    width: 120.w,
                    onPressed: () {},
                  btnChild: Text(
                    'Play Now',
                    style: AppTextStyles.poppinsSemiBold.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionHeader({
     required String title,
     required bool showViewAll,
     VoidCallback? onViewAll,
}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 16.sp,
              color: AppColors.white,
            ),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                "View All",
                style: AppTextStyles.poppinsMedium.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.brandYellowColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gameModes() {
    return Column(
      children: [
        SizedBox(height: 11.h,),
        _selectionHeader(
          title: "Game Modes",
          showViewAll: false,
          onViewAll: () {
            // handle navigation or action
          },
        ),
        SizedBox(height: 4.h,),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children:  [
            _matchModelCard(
              icon: AppImages.tournament,
              title: 'Tournament',
              subtitle: 'Compete & win',
              onTap: () {
                context.push('/dashboard?tab=2');
              },
            ),
            _matchModelCard(
              icon: AppImages.game,
              title: 'Quick Play',
              subtitle: 'Play rooms',
              onTap: () {
                context.push('/dashboard?tab=1');
              },
            ),
          ],
        ),
      ],
    );
  }


  Widget _liveTournaments() {
    final tournaments = context.watch<TournamentProvider>().activeTournaments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18.h),
        _selectionHeader(
          title: "Live Tournaments",
          showViewAll: true,
          // showViewAll: tournaments.isNotEmpty,
          onViewAll: () {
            // handle navigation or action
          },
        ),
        SizedBox(height: 4.h),
        if (tournaments.isNotEmpty)
          ListView.separated(
            itemBuilder: (context, index) {
              return _tornamentCard(data: tournaments[index]);
            },
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            shrinkWrap: true,
            itemCount: tournaments.length,
            physics: const NeverScrollableScrollPhysics(),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child:  Center(
              child: Text(
                "No live tournaments available",
                style: AppTextStyles.poppinsRegular.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentGames() {
    final recentGames = context.watch<GameProvider>().recentGames;
    if(recentGames.isNotEmpty){
      return Column(
        children: [
          SizedBox(height: 8.h,),
          _selectionHeader(
            title: "Recent Games",
            showViewAll: false,
            onViewAll: () {
              // handle navigation or action
            },
          ),
          SizedBox(height: 8.h,),
          ListView.separated(
            itemBuilder: (context, index) {
              return _recentTournamentCard(index);
            },
            separatorBuilder: (context, index) {
              return SizedBox(height: 12.h,);
            },
            shrinkWrap: true,
            itemCount: recentGames.length,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _matchModelCard({
     required String icon,
     required String title,
     required String subtitle,
     void Function()? onTap
}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 171.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: AppGradients.blueHorizontal,
          borderRadius: BorderRadius.circular(12.r),
          // border: Border.all(
          //   color: Color(0xFFE5E7EB),
          //   width: 1,
          // ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Yellow circular icon background
            Container(
              width: 48.w,
              height: 48.w,
              padding: EdgeInsets.all(12.h),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandYellowColor,
              ),
              child: svgIcon(
                name: icon,
                width: 20.w,
                  height: 13.h,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 16.sp,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppTextStyles.poppinsRegular.copyWith(
                fontSize: 12.sp,
                color: Color(0xffBFDBFE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tornamentCard({required Map<String,dynamic> data}) {
    return InkWell(
      onTap: () async {
        final provider = context.read<TournamentProvider>();
        await provider.fetchParticipants(data['id']);
        final uid = await AppPreferences().getUserId();
        final joined = provider.participants.any((p) => p['user_id'] == uid);
        if (joined) {
          context.push('/dashboard?tab=2&tournament=${data['id']}');
          return;
        }
        if (data['is_active'] ?? false) {
          final wallet = context.read<WalletProvider>().totalAmount;
          final fee = (data['join_fee'] ?? 0).toDouble();
          if (wallet >= fee) {
            final confirm =
                await showJoinTournamentDialog(context, fee: fee) ?? false;
            if (!confirm) return;

              final result = await provider.join(data['id'], context);
            if (result.isSuccess) {
              await context.read<WalletProvider>().load();
              final gameId = result.data?['game_id'] as int?;
              if (gameId != null) {
                context.push('/game/$gameId');
              } else {
                context.push('/dashboard?tab=2&tournament=${data['id']}');
              }
            } else {
              final msg = localizeError(result.code, result.error!);
              CommonToast.error(msg);
            }
          } else {
            final need = fee - wallet;
            context.push('/deposit?amount=${need.toStringAsFixed(0)}');
          }
        } else {
          context.push('/tournament/${data['id']}/leaderboard');
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: AppGradients.blueHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${data['name']??''}",
                    style: AppTextStyles.poppinsSemiBold.copyWith(
                      fontSize: 14.sp,
                      color:AppColors.brandYellowColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    "Live",
                    style: AppTextStyles.poppinsRegular.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        "${"₹${data['prize_slab'].isNotEmpty ? data['prize_slab'][0]['amount'] ?? 0 : 0}"} Prize Pool",
                        style: AppTextStyles.poppinsSemiBold.copyWith(
                          fontSize: 16.sp,
                          color:AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "Entry: ₹${data['join_fee']??0.0}",
                        style: AppTextStyles.poppinsRegular.copyWith(
                          fontSize: 14.sp,
                          color:const Color(0xffBFDBFE),
                        ),
                      ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                      Text(
                        "0/${data['seat_limit']??0}",
                        style: AppTextStyles.poppinsSemiBold.copyWith(
                          fontSize: 16.sp,
                          color:AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "players",
                        style: AppTextStyles.poppinsRegular.copyWith(
                          fontSize: 14.sp,
                          color:const Color(0xffBFDBFE),
                        ),
                      ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTournamentCard(index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            height: 40.h,
            width: 40.w,
            padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == 0
                    ? getTransactionColor('won')
                    : getTransactionColor('lost'),
              ),
            child: svgIcon(
              name: index == 0 ? AppImages.tournament : AppImages.cancel,
              width: 15.w,
              height: 15.h,
              color: AppColors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index == 0 ?
                  "You Won!" : "Close Game",
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 16.sp,
                    color:AppColors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "vs 3 players",
                  style: AppTextStyles.poppinsRegular.copyWith(
                    fontSize: 14.sp,
                    color:Color(0xffBFDBFE),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                Text(
                  index == 0 ? "+₹500" : "-₹50",
                  style: AppTextStyles.poppinsSemiBold.copyWith(
                    fontSize: 16.sp,
                    color: index == 0
                        ? getTransactionColor('won')
                        : getTransactionColor('lost'),
                  ),
                ),
              SizedBox(height: 4.h),
              Text(
                "5 hours ago",
                style: AppTextStyles.poppinsRegular.copyWith(
                  fontSize: 14.sp,
                  color:Color(0xffBFDBFE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
