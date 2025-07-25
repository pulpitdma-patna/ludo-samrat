import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_images.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme.dart';
import '../utils/svg_icon.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _transactionsOpen = false;

  Widget _drawerItem({
    required BuildContext context,
    required String label,
    required String route,
    String iconPath = '',
    IconData? icon,
    bool highlightError = false,
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final router = GoRouter.of(context);
    final currentLocation = router.routeInformationProvider.value.uri.toString();
    final isActive = currentLocation.startsWith(route.split('?').first);
    final activeColor = highlightError
        ? Theme.of(context).colorScheme.error
        : AppColors.activeColor;
    final itemColor = isActive
        ? activeColor
        : textTheme.bodyMedium?.color;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
        } else {
          context.push(route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.1)
              : Colors.transparent,
          border: isActive
              ? Border(
                  left: BorderSide(color: activeColor, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            if (iconPath.isNotEmpty)
              svgIcon(
                name: iconPath,
                width: 24,
                height: 24,
                color: itemColor,
              )
            else if (icon != null)
              Icon(
                icon,
                color: itemColor,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: itemColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: textTheme.labelLarge?.copyWith(
          color: AppColors.smallTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final router = GoRouter.of(context);
    final currentLocation = router.routeInformationProvider.value.uri.toString();
    final isTransactionsActive =
        currentLocation.startsWith('/wallet/transactions');

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.pop(context);
        }
      },
      child: Drawer(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGradient,
                  AppColors.secondPrimaryGradient,
                  AppColors.secondPrimaryGradient,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: svgIcon(
                        name: AppImages.close,
                        width: 20,
                        height: 20,
                        color: AppColors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Consumer<ProfileProvider>(
                      builder: (context, profile, _) {
                        final url = profile.avatarUrl;
                        final name = profile.name ?? 'Guest';
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.transparent,
                              backgroundImage: url != null && url.isNotEmpty
                                  ? NetworkImage(url)
                                  : null,
                              child: url == null || url.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            Consumer<WalletProvider>(
                              builder: (context, wallet, __) {
                                return Text(
                                  '₹${wallet.totalAmount.toStringAsFixed(2)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.smallTextColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          _sectionHeader('Account', context),
          _drawerItem(
            context: context,
            label: 'My Account',
            route: '/profile',
            iconPath: AppImages.profile,
          ),
          _drawerItem(
            context: context,
            label: 'Withdrawals',
            route: '/withdraw',
            iconPath: AppImages.withdraw,
          ),
          _sectionHeader('Wallet', context),
          _drawerItem(
            context: context,
            label: 'Bonus Cash',
            route: '/bonus-cash',
            iconPath: AppImages.reward,
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isTransactionsActive
                    ? AppColors.activeColor.withOpacity(0.1)
                    : Colors.transparent,
                border: isTransactionsActive
                    ? const Border(
                        left: BorderSide(
                          color: AppColors.activeColor,
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: ExpansionTile(
                initiallyExpanded: isTransactionsActive,
                onExpansionChanged: (v) => setState(() => _transactionsOpen = v),
                leading: svgIcon(
                  name: AppImages.history,
                  width: 24,
                  height: 24,
                  color: isTransactionsActive
                      ? AppColors.activeColor
                      : textTheme.bodyMedium?.color,
                ),
                title: Text(
                  'Transactions',
                  style: textTheme.bodyMedium?.copyWith(
                    color: isTransactionsActive ? AppColors.activeColor : null,
                  ),
                ),
                childrenPadding: EdgeInsets.zero,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                children: [
                  _drawerItem(
                    context: context,
                    label: 'All Transactions',
                    route: '/wallet/transactions',
                    iconPath: AppImages.history,
                  ),
                ],
              ),
            ),
          ),
          _sectionHeader('Support', context),
          _drawerItem(
            context: context,
            label: 'Help & Support',
            route: '/help',
            iconPath: AppImages.invite,
          ),
          _drawerItem(
            context: context,
            label: 'Terms & Conditions',
            route: '/terms',
            iconPath: AppImages.cancel,
          ),
          _drawerItem(
            context: context,
            label: 'Responsible Play',
            route: '/responsible-play',
            iconPath: AppImages.game,
          ),
          _drawerItem(
            context: context,
            label: 'How to Play Lodu Samat',
            route: '/how-to-play',
            iconPath: AppImages.quickMatch,
          ),
          _drawerItem(
            context: context,
            label: 'Promotions',
            route: '/promotions',
            iconPath: AppImages.crown,
          ),
          _drawerItem(
            context: context,
            label: 'Logout',
            route: '/login',
            icon: Icons.logout,
            highlightError: true,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    ),
  );
  }
}
