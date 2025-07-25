import 'package:flutter/material.dart';
import '../services/theme_storage.dart';
import 'package:frontend/main.dart';

/// Icon button that toggles between light and dark mode.
class ThemeModeSwitch extends StatelessWidget {
  const ThemeModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.white),
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: () {
            final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
            themeNotifier.value = nextMode;
            ThemeStorage.setThemeMode(nextMode);
          },
        );
      },
    );
  }
}
