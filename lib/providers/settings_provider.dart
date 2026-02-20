import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ru'),
  });

  final ThemeMode themeMode;
  final Locale locale;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

final settingsStorageProvider = Provider<SettingsStorage>(
  (ref) => const SettingsStorage(),
);

final settingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  return AppSettingsNotifier(storage);
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._storage) : super(const AppSettings()) {
    _restore();
  }

  final SettingsStorage _storage;

  void toggleThemeMode() {
    final nextTheme =
        state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: nextTheme);
    unawaited(_storage.saveThemeMode(state.themeMode));
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == state.themeMode) return;
    state = state.copyWith(themeMode: mode);
    unawaited(_storage.saveThemeMode(mode));
  }

  void setLocale(Locale locale) {
    if (locale == state.locale) return;
    state = state.copyWith(locale: locale);
    unawaited(_storage.saveLocale(locale));
  }

  Future<void> _restore() async {
    final saved = await _storage.load();
    if (saved != null) {
      state = saved;
    }
  }
}

class SettingsStorage {
  const SettingsStorage();

  static const _themeKey = 'settings.theme_mode';
  static const _localeKey = 'settings.locale';

  Future<AppSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    final localeCode = prefs.getString(_localeKey);

    if (themeName == null && localeCode == null) {
      return null;
    }

    final themeMode = _themeModeFromName(themeName) ?? ThemeMode.system;
    final locale = localeCode != null ? _localeFromCode(localeCode) : null;

    return AppSettings(
      themeMode: themeMode,
      locale: locale ?? const Locale('ru'),
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, _encodeLocale(locale));
  }

  static ThemeMode? _themeModeFromName(String? name) {
    switch (name) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
    }
    return null;
  }

  static Locale _localeFromCode(String code) {
    final parts = code.split('_');
    if (parts.length > 1) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts.first);
  }

  static String _encodeLocale(Locale locale) {
    final country = locale.countryCode;
    if (country != null && country.isNotEmpty) {
      return '${locale.languageCode}_$country';
    }
    return locale.languageCode;
  }
}
