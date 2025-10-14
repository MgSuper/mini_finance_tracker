import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Read API key from --dart-define or env-like value.
/// Pass when running: --dart-define=OPENAI_API_KEY=sk-xxxx
const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

final useAiInsightsProvider =
    StateNotifierProvider<UseAiInsightsController, bool>((ref) {
  return UseAiInsightsController();
});

class UseAiInsightsController extends StateNotifier<bool> {
  UseAiInsightsController() : super(false) {
    _load();
  }

  static const _k = 'use_ai_insights';

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    state = sp.getBool(_k) ?? false;
  }

  Future<void> toggle() async {
    final sp = await SharedPreferences.getInstance();
    state = !state;
    await sp.setBool(_k, state);
  }

  Future<void> set(bool v) async {
    final sp = await SharedPreferences.getInstance();
    state = v;
    await sp.setBool(_k, v);
  }
}
