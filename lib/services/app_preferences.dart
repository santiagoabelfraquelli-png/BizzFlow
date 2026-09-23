import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  static const String _themeModeKey = 'themeMode';
  static const String _rememberLoginKey = 'rememberLogin';

  bool? _rememberLoginCache;

  bool get rememberLogin => _rememberLoginCache ?? false;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();

    _rememberLoginCache =
        preferences.getBool(_rememberLoginKey) ?? false;
  }

  Future<bool> getRememberLogin() async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getBool(_rememberLoginKey) ?? false;
    _rememberLoginCache = value;

    return value;
  }

  Future<void> setRememberLogin(bool value) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _rememberLoginKey,
      value,
    );

    _rememberLoginCache = value;
  }

  Future<String> getThemeMode() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_themeModeKey) ?? 'system';
  }

  Future<void> setThemeMode(String themeMode) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _themeModeKey,
      themeMode,
    );
  }
}