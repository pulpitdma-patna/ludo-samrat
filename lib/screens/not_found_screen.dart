import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common_widget/app_scaffold.dart';
import '../common_widget/common_appbar.dart';
import '../theme.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: GradientAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Page Not Found'),
      ),
      body: const Center(
        child: Text(
          '404 - Page not found',
          style: TextStyle(color: AppColors.white, fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
