import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _k = 'app_theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final i = sp.getInt(_k); // 0=system,1=light,2=dark
    if (i != null) state = ThemeMode.values[i.clamp(0, 2)];
  }

  Future<void> set(ThemeMode m) async {
    state = m;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_k, m.index);
  }

  Future<void> toggle() async {
    // Light <-> Dark; keep System as Light for simplicity
    final next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
    await set(next);
  }
}
