import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import '../providers/settings_provider.dart';
import 'board_theme.dart';
import 'board_colors.dart';
import 'board_orientation.dart';
import 'token_icon.dart';
import 'token_color.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';

class BoardPreferencesScreen extends StatelessWidget {
  const BoardPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Board Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Token Icon: '),
                const SizedBox(width: 12),
                DropdownButton<TokenIcon>(
                  value: provider.tokenIcon,
                  onChanged: (i) => provider.setTokenIcon(i!),
                  items: TokenIcon.values
                      .map(
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Icon(i.icon),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Token Color: '),
                const SizedBox(width: 12),
                DropdownButton<TokenColor>(
                  value: provider.tokenColor,
                  onChanged: (c) => provider.setTokenColor(c!),
                  items: TokenColor.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.color,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
