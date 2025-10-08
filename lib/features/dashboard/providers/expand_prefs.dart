import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A generic AsyncNotifier that persists an expanded/collapsed boolean
/// under a unique SharedPreferences key.
class ExpandSectionNotifier extends AsyncNotifier<bool> {
  ExpandSectionNotifier(this.prefKey);
  final String prefKey;

  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? false; // default collapsed
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    final next = !current;
    state = AsyncData(next); // optimistic
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, next);
    } catch (_) {
      // ignore – UI stays optimistic, will sync next launch
    }
  }

  Future<void> setExpanded(bool expanded) async {
    state = AsyncData(expanded);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, expanded);
    } catch (_) {
      // ignore
    }
  }
}
