import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/theme.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'board_theme.dart';
import 'board_colors.dart';
import 'board_orientation.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
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
                color: AppColors.white,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'Settings',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Token Size: ${provider.tokenSize.toStringAsFixed(0)}'),
            Slider(
              min: 12,
              max: 32,
              divisions: 20,
              value: provider.tokenSize,
              label: provider.tokenSize.toStringAsFixed(0),
              onChanged: (v) => provider.setTokenSize(v),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('High Contrast Mode'),
              value: provider.highContrast,
              onChanged: (v) => provider.setHighContrast(v),
            ),
            Text('Board Contrast: ${provider.boardSaturation.toStringAsFixed(2)}'),
            Slider(
              min: 0,
              max: 2,
              divisions: 20,
              value: provider.boardSaturation,
              label: provider.boardSaturation.toStringAsFixed(2),
              onChanged: (v) => provider.setBoardSaturation(v),
            ),
            SwitchListTile(
              title: const Text('Board Shadows'),
              value: provider.boardShadows,
              onChanged: (v) => provider.setBoardShadows(v),
            ),
            SwitchListTile(
              title: const Text('Color Blind Mode'),
              value: provider.colorBlindMode,
              onChanged: (v) => provider.setColorBlindMode(v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Board Theme: '),
                const SizedBox(width: 12),
                DropdownButton<BoardTheme>(
                  value: provider.boardTheme,
                  onChanged: (t) => provider.setBoardTheme(t!),
                  items: BoardTheme.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Board Colors: '),
                const SizedBox(width: 12),
                DropdownButton<BoardPalette>(
                  value: provider.boardPalette,
                  onChanged: (p) => provider.setBoardPalette(p!),
                  items: BoardPalette.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.name[0].toUpperCase() + p.name.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Board Orientation: '),
                const SizedBox(width: 12),
                DropdownButton<BoardOrientation>(
                  value: provider.orientation,
                  onChanged: (o) => provider.setOrientation(o!),
                  items: BoardOrientation.values
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text('${o.index * 90}\u00B0'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Color Blind Mode overlays symbols on tokens to help '
              'distinguish players.',
            ),
          ],
        ),
      ),
    );
  }
}
