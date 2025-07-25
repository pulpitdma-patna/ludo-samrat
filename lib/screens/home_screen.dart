import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/app_images.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import '../theme.dart';
import 'home_dashboard.dart';
import '../common_widget/app_scaffold.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        showThemeSwitch: true,
        leading: GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Image.asset(
            AppImages.logo,
            width: 81.w,
            fit: BoxFit.cover,
          ),
        ),
        suffixIcon: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Consumer<ProfileProvider>(
              builder: (context, profile, _) {
                final url = profile.avatarUrl;
                return CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.transparent,
                  backgroundImage:
                      url != null && url.isNotEmpty ? NetworkImage(url) : null,
                  child: url == null || url.isEmpty
                      ? Icon(Icons.person, color: Colors.yellow, size: 20)
                      : null,
                );
              },
            ),
          ),
        ),
      ),
      body: const HomeDashboard(),
    );
  }
}
