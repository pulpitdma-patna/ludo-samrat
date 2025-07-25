enum BoardTheme { classic, modern, wooden, glass }

extension BoardThemeData on BoardTheme {
  String get displayName {
    switch (this) {
      case BoardTheme.modern:
        return 'Modern';
      case BoardTheme.wooden:
        return 'Wooden';
      case BoardTheme.glass:
        return 'Modern Glass';
      case BoardTheme.classic:
      default:
        return 'Classic';
    }
  }
}
