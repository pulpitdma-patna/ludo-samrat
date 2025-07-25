import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:frontend/common_widget/common_loader.dart';
import '../providers/public_settings_provider.dart';
import '../theme.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool isLoading;
  final Gradient? backgroundGradient;
  final Color? backgroundColor;
  final String? backgroundImage;
  final String? backgroundImageUrl;
  const AppScaffold({
    Key? key,
    this.appBar,
    this.body,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.isLoading = false,
    this.backgroundGradient,
    this.backgroundColor,
    this.backgroundImage,
    this.backgroundImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Default to the theme's card color so admins can override via settings.
    final defaultColor = Theme.of(context).cardColor;

    final settingsUrl =
        context.watch<PublicSettingsProvider>().backgroundImageUrl;
    final url = backgroundImageUrl ?? settingsUrl;
    final asset = backgroundImage;
    final bg = url ?? asset;
    final isNetwork = url != null;
    if (isNetwork) {
      debugPrint('Using background image: $bg');
    }
    final isDataUri = bg != null && bg.startsWith('data:image');
    final data = isDataUri ? Uri.parse(bg!).data : null;
    final isSvg = (bg != null && bg.toLowerCase().endsWith('.svg')) ||
        (data?.mimeType == 'image/svg+xml');

    Widget container = Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (backgroundGradient == null && bg == null ? defaultColor : null),
        gradient: backgroundColor == null ? backgroundGradient : null,
        image: !isSvg && bg != null
            ? DecorationImage(
                image: isDataUri
                    ? MemoryImage(data!.contentAsBytes())
                    : isNetwork
                        ? NetworkImage(bg)
                        : AssetImage(bg) as ImageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: body,
    );

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const CommonLoader()
          : (isSvg && bg != null
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: isDataUri
                          ? SvgPicture.memory(data!.contentAsBytes(),
                              fit: BoxFit.cover)
                          : isNetwork
                              ? SvgPicture.network(bg, fit: BoxFit.cover)
                              : SvgPicture.asset(bg, fit: BoxFit.cover),
                    ),
                    container,
                  ],
                )
              : container),
    );
  }
}
