import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'hs-feed-layout-grid';

/// Persists whether post feeds render as a multi-column grid or a single-column list.
class FeedLayoutController extends ChangeNotifier {
  bool _useGrid = true;
  bool _initializing = true;

  bool get useGrid => _useGrid;
  bool get initializing => _initializing;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useGrid = prefs.getBool(_storageKey) ?? true;
    } catch (_) {
      _useGrid = true;
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> setUseGrid(bool useGrid) async {
    if (_useGrid == useGrid) return;
    _useGrid = useGrid;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, useGrid);
    } catch (_) {}
  }

  Future<void> toggle() => setUseGrid(!_useGrid);
}
