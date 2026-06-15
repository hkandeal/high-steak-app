import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';

const _storageKey = 'hs-theme';

class ThemeController extends ChangeNotifier {
  AppThemeVariant _variant = AppThemeVariant.ember;
  bool _initializing = true;

  AppThemeVariant get variant => _variant;
  bool get initializing => _initializing;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == 'steam') {
        _variant = AppThemeVariant.steam;
      }
    } catch (_) {
      // Keep default ember theme.
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    if (_variant == variant) return;
    _variant = variant;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        variant == AppThemeVariant.steam ? 'steam' : 'ember',
      );
    } catch (_) {}
  }

  Future<void> toggle() async {
    await setVariant(
      _variant == AppThemeVariant.ember
          ? AppThemeVariant.steam
          : AppThemeVariant.ember,
    );
  }
}
