import 'package:flutter/material.dart';
import '../services/board_settings_storage.dart';
import '../screens/board_theme.dart';
import '../screens/board_orientation.dart';
import '../screens/token_icon.dart';
import '../screens/token_color.dart';
import '../screens/board_colors.dart';

class SettingsProvider extends ChangeNotifier {
  double _tokenSize = 20.0;
  bool _highContrast = false;
  bool _colorBlind = false;
  BoardTheme _boardTheme = BoardTheme.classic;
  BoardPalette _boardPalette = BoardPalette.classic;
  BoardOrientation _orientation = BoardOrientation.deg0;

  double _boardSaturation = 1.0;

  bool _boardShadows = true;

  TokenIcon _tokenIcon = TokenIcon.circle;
  TokenColor _tokenColor = TokenColor.red;


  double get tokenSize => _tokenSize;
  bool get highContrast => _highContrast;
  bool get colorBlindMode => _colorBlind;
  BoardTheme get boardTheme => _boardTheme;
  BoardPalette get boardPalette => _boardPalette;
  BoardOrientation get orientation => _orientation;

  double get boardSaturation => _boardSaturation;

  bool get boardShadows => _boardShadows;

  TokenIcon get tokenIcon => _tokenIcon;
  TokenColor get tokenColor => _tokenColor;


  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    _tokenSize = await BoardSettingsStorage.getTokenSize();
    _highContrast = await BoardSettingsStorage.getHighContrast();
    _colorBlind = await BoardSettingsStorage.getColorBlind();
    _boardTheme = await BoardSettingsStorage.getBoardTheme();
    _boardPalette = await BoardSettingsStorage.getBoardPalette();
    _orientation = await BoardSettingsStorage.getOrientation();

    _boardSaturation = await BoardSettingsStorage.getBoardSaturation();

    _boardShadows = await BoardSettingsStorage.getBoardShadows();

    _tokenIcon = await BoardSettingsStorage.getTokenIcon();
    _tokenColor = await BoardSettingsStorage.getTokenColor();

    notifyListeners();
  }

  Future<void> setTokenSize(double size) async {
    _tokenSize = size;
    notifyListeners();
    await BoardSettingsStorage.setTokenSize(size);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await BoardSettingsStorage.setHighContrast(value);
  }

  Future<void> setColorBlindMode(bool value) async {
    _colorBlind = value;
    notifyListeners();
    await BoardSettingsStorage.setColorBlind(value);
  }

  Future<void> setBoardTheme(BoardTheme theme) async {
    _boardTheme = theme;
    notifyListeners();
    await BoardSettingsStorage.setBoardTheme(theme);
  }

  Future<void> setBoardPalette(BoardPalette palette) async {
    _boardPalette = palette;
    notifyListeners();
    await BoardSettingsStorage.setBoardPalette(palette);
  }

  Future<void> setBoardSaturation(double value) async {
    _boardSaturation = value;
    notifyListeners();
    await BoardSettingsStorage.setBoardSaturation(value);
  }

  Future<void> setBoardShadows(bool value) async {
    _boardShadows = value;
    notifyListeners();
    await BoardSettingsStorage.setBoardShadows(value);
  }

  Future<void> setOrientation(BoardOrientation orientation) async {
    _orientation = orientation;
    notifyListeners();
    await BoardSettingsStorage.setOrientation(orientation);
  }

  Future<void> setTokenIcon(TokenIcon icon) async {
    _tokenIcon = icon;
    notifyListeners();
    await BoardSettingsStorage.setTokenIcon(icon);
  }

  Future<void> setTokenColor(TokenColor color) async {
    _tokenColor = color;
    notifyListeners();
    await BoardSettingsStorage.setTokenColor(color);
  }
}
