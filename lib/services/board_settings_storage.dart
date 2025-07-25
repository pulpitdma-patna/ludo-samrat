import 'package:shared_preferences/shared_preferences.dart';
import '../screens/board_theme.dart';
import '../screens/board_orientation.dart';
import '../screens/token_icon.dart';
import '../screens/token_color.dart';
import '../screens/board_colors.dart';

class BoardSettingsStorage {
  static const _tokenSizeKey = 'token_size';
  static const _highContrastKey = 'high_contrast';
  static const _colorBlindKey = 'color_blind';
  static const _boardThemeKey = 'board_theme';
  static const _boardPaletteKey = 'board_palette';
  static const _orientationKey = 'board_orientation';

  static const _boardSaturationKey = 'board_saturation';
  static const _boardShadowsKey = 'board_shadows';

  static const _tokenIconKey = 'token_icon';
  static const _tokenColorKey = 'token_color';


  static Future<double> getTokenSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_tokenSizeKey) ?? 20.0;
  }

  static Future<void> setTokenSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_tokenSizeKey, size);
  }

  static Future<bool> getHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  static Future<bool> getColorBlind() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_colorBlindKey) ?? false;
  }

  static Future<void> setHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }

  static Future<void> setColorBlind(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_colorBlindKey, value);
  }

  static Future<BoardTheme> getBoardTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_boardThemeKey) ?? 0;
    return BoardTheme.values[index];
  }

  static Future<BoardPalette> getBoardPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_boardPaletteKey) ?? 0;
    return BoardPalette.values[index];
  }

  static Future<void> setBoardTheme(BoardTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_boardThemeKey, theme.index);
  }

  static Future<void> setBoardPalette(BoardPalette palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_boardPaletteKey, palette.index);
  }

  static Future<BoardOrientation> getOrientation() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_orientationKey) ?? 0;
    return BoardOrientation.values[index];
  }

  static Future<double> getBoardSaturation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_boardSaturationKey) ?? 1.0;
  }

  static Future<void> setBoardSaturation(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_boardSaturationKey, value);
  }

  static Future<bool> getBoardShadows() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_boardShadowsKey) ?? true;
  }

  static Future<void> setBoardShadows(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_boardShadowsKey, value);
  }

  static Future<void> setOrientation(BoardOrientation orientation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_orientationKey, orientation.index);
  }

  static Future<TokenIcon> getTokenIcon() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_tokenIconKey) ?? 0;
    return TokenIcon.values[index];
  }

  static Future<void> setTokenIcon(TokenIcon icon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenIconKey, icon.index);
  }

  static Future<TokenColor> getTokenColor() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_tokenColorKey) ?? 0;
    return TokenColor.values[index];
  }

  static Future<void> setTokenColor(TokenColor color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenColorKey, color.index);
  }
}
