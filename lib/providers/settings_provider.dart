import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _prefThemeMode = 'settings_theme_mode';
  static const String _prefLocale = 'settings_locale';
  
  // Admin Notification Settings
  static const String _prefEmailUserReports = 'admin_email_user_reports';
  static const String _prefEmailNewRegistrations = 'admin_email_new_registrations';
  static const String _prefEmailSystemAlerts = 'admin_email_system_alerts';
  static const String _prefEmailContentFlags = 'admin_email_content_flags';
  static const String _prefEmailDailyDigest = 'admin_email_daily_digest';
  static const String _prefPushUserReports = 'admin_push_user_reports';
  static const String _prefPushNewRegistrations = 'admin_push_new_registrations';
  static const String _prefPushSystemAlerts = 'admin_push_system_alerts';
  static const String _prefPushContentFlags = 'admin_push_content_flags';
  static const String _prefNotificationFrequency = 'admin_notification_frequency';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');
  bool _initialized = false;

  // Admin Notification Settings
  bool _emailUserReports = true;
  bool _emailNewRegistrations = true;
  bool _emailSystemAlerts = true;
  bool _emailContentFlags = true;
  bool _emailDailyDigest = false;
  bool _pushUserReports = true;
  bool _pushNewRegistrations = false;
  bool _pushSystemAlerts = true;
  bool _pushContentFlags = true;
  String _notificationFrequency = 'instant';

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get initialized => _initialized;
  
  // Admin Notification Getters
  bool get emailUserReports => _emailUserReports;
  bool get emailNewRegistrations => _emailNewRegistrations;
  bool get emailSystemAlerts => _emailSystemAlerts;
  bool get emailContentFlags => _emailContentFlags;
  bool get emailDailyDigest => _emailDailyDigest;
  bool get pushUserReports => _pushUserReports;
  bool get pushNewRegistrations => _pushNewRegistrations;
  bool get pushSystemAlerts => _pushSystemAlerts;
  bool get pushContentFlags => _pushContentFlags;
  String get notificationFrequency => _notificationFrequency;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_prefThemeMode);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    final localeCode = prefs.getString(_prefLocale);
    if (localeCode != null && localeCode.isNotEmpty) {
      _locale = Locale(localeCode);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeMode, mode.index);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLocale, locale.languageCode);
  }

  Future<void> loadAdminNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _emailUserReports = prefs.getBool(_prefEmailUserReports) ?? true;
    _emailNewRegistrations = prefs.getBool(_prefEmailNewRegistrations) ?? true;
    _emailSystemAlerts = prefs.getBool(_prefEmailSystemAlerts) ?? true;
    _emailContentFlags = prefs.getBool(_prefEmailContentFlags) ?? true;
    _emailDailyDigest = prefs.getBool(_prefEmailDailyDigest) ?? false;
    _pushUserReports = prefs.getBool(_prefPushUserReports) ?? true;
    _pushNewRegistrations = prefs.getBool(_prefPushNewRegistrations) ?? false;
    _pushSystemAlerts = prefs.getBool(_prefPushSystemAlerts) ?? true;
    _pushContentFlags = prefs.getBool(_prefPushContentFlags) ?? true;
    _notificationFrequency = prefs.getString(_prefNotificationFrequency) ?? 'instant';
    notifyListeners();
  }

  Future<void> saveAdminNotificationSettings({
    required bool emailUserReports,
    required bool emailNewRegistrations,
    required bool emailSystemAlerts,
    required bool emailContentFlags,
    required bool emailDailyDigest,
    required bool pushUserReports,
    required bool pushNewRegistrations,
    required bool pushSystemAlerts,
    required bool pushContentFlags,
    required String notificationFrequency,
  }) async {
    _emailUserReports = emailUserReports;
    _emailNewRegistrations = emailNewRegistrations;
    _emailSystemAlerts = emailSystemAlerts;
    _emailContentFlags = emailContentFlags;
    _emailDailyDigest = emailDailyDigest;
    _pushUserReports = pushUserReports;
    _pushNewRegistrations = pushNewRegistrations;
    _pushSystemAlerts = pushSystemAlerts;
    _pushContentFlags = pushContentFlags;
    _notificationFrequency = notificationFrequency;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEmailUserReports, emailUserReports);
    await prefs.setBool(_prefEmailNewRegistrations, emailNewRegistrations);
    await prefs.setBool(_prefEmailSystemAlerts, emailSystemAlerts);
    await prefs.setBool(_prefEmailContentFlags, emailContentFlags);
    await prefs.setBool(_prefEmailDailyDigest, emailDailyDigest);
    await prefs.setBool(_prefPushUserReports, pushUserReports);
    await prefs.setBool(_prefPushNewRegistrations, pushNewRegistrations);
    await prefs.setBool(_prefPushSystemAlerts, pushSystemAlerts);
    await prefs.setBool(_prefPushContentFlags, pushContentFlags);
    await prefs.setString(_prefNotificationFrequency, notificationFrequency);
    
    notifyListeners();
  }
}


