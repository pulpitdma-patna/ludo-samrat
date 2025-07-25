import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/common_widget/common_button.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/utils/svg_icon.dart';
import '../common_widget/app_scaffold.dart';
import '../widgets/stat_box.dart';
import 'package:provider/provider.dart';
import '../services/profile_api.dart';
import '../services/theme_storage.dart';
import 'package:frontend/main.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_drawer.dart';


class ProfileScreen extends StatefulWidget {
  final ProfileApi api;
  ProfileScreen({super.key, ProfileApi? api}) : api = api ?? ProfileApi();

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _avatarController = TextEditingController();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
      context.read<ProfileProvider>().getProfile(),
      context.read<ProfileProvider>().getMe(),
      ]);
      _loadTheme();
    });
    // _load();

  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ProfileProvider>().getProfile(),
      context.read<ProfileProvider>().getMe(),
    ]);
  }

  void _load() async {
    final result = await widget.api.getProfile();
    if (result.isSuccess) {
      final data = result.data;
      setState(() {
        _avatarController.text = data?['avatar_url'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  void _save() async {
    final result = await widget.api.setAvatar(_avatarController.text);
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  void _loadTheme() async {
    final mode = await ThemeStorage.getThemeMode();
    setState(() => _themeMode = mode);
  }

  void _toggleTheme(ThemeMode? mode) async {
    if (mode == null) return;
    setState(() => _themeMode = mode);
    themeNotifier.value = mode;
    await ThemeStorage.setThemeMode(mode);
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
      return AppScaffold(
        isLoading: profile.isLoading,
        drawer: const AppDrawer(),
        appBar: GradientAppBar(
          leading: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
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
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                "Profile",
                textAlign: TextAlign.start,
                style: AppTextStyles.poppinsSemiBold.copyWith(
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
          suffixIcon: GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.1),
              ),
              child: Center(child: Icon(Icons.settings, size: 20.h)),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal.w,
              vertical: AppSpacing.section.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 40.h),
                  _buildStatsGrid(),
                  SizedBox(height: 24.h),
                  _buildPayNowButton(),
                ],
              ),
            ),
          ),
        ),
      );
    },);
  }

  Widget _buildProfileHeader() {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final url = profile.avatarUrl;
        final name = profile.name ?? "Guest"; // fallback if name is null
        return Column(
          children: [
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: SizedBox(
                width: 102.w,
                height: 102.w,
                child: Stack(
                  children: [
                  Positioned(
                    bottom: 4.0,
                    right: 1.0,
                    child: Container(
                      height: 32.w,
                      width: 32.w,
                      padding: EdgeInsets.all(6.h),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFBBF24),
                      ),
                        child: svgIcon(
                          name: AppImages.crown,
                          width: 14.w,
                          height: 14.h,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ),
                  ),
                  Container(
                    height: 96.w,
                    width: 96.w,
                    decoration: BoxDecoration(
                      color: const Color(0xff1E40AF),
                      borderRadius: BorderRadius.circular(48.r),
                      border: Border.all(
                        color: const Color(0xFFFBBF24),
                        width: 4.w,
                      ),
                      image: DecorationImage(
                        image: url != null && url.isNotEmpty
                            ? NetworkImage(url)
                            : const AssetImage(AppImages.temp_logo)
                        as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      height: 28.w,
                      width: 28.w,
                      padding: EdgeInsets.all(6.h),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: svgIcon(
                        name: AppImages.edit,
                        width: 16.w,
                        height: 16.h,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              style: AppTextStyles.poppinsBold.copyWith(
                fontSize: 24.sp,
              ),
            ),
            SizedBox(height: 4.h),
          ],
        );
      },
    );
  }


  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 170 / 102,
      children: [
        StatBox(
          value: "0",
          label: "Wins",
          iconPath: AppImages.tournament,
          backgroundColor: Theme.of(context).cardColor.withOpacity(0.1),
          border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16.r),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontal.w,
            vertical: 8.h,
          ),
          valueColor: Theme.of(context).colorScheme.onBackground,
          labelColor: const Color(0xffBFDBFE),
          iconColor: const Color(0xffFBBF24),
        ),
        StatBox(
          value: "0",
          label: "Games",
          iconPath: AppImages.game,
          backgroundColor: Theme.of(context).cardColor.withOpacity(0.1),
          border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16.r),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontal.w,
            vertical: 8.h,
          ),
          valueColor: Theme.of(context).colorScheme.onBackground,
          labelColor: const Color(0xffBFDBFE),
          iconColor: const Color(0xffFBBF24),
        ),
      ],
    );
  }


  Widget _buildPayNowButton() {
    return CommonButton(
      text: '',
      btnTextColor: Colors.white,
      btnChild: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            svgIcon(
              name: AppImages.lostGame,
              width: 16.w,
              height: 16.h,
              color: Theme.of(context).colorScheme.primary,
              semanticsLabel: 'refer & earn',
          ),
          SizedBox(width: 8.w),
          Text(
            'Refer & Earn',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
          )
        ],
      ),
      onPressed: () {
        context.push('/referral');
      },
    );
  }
}
