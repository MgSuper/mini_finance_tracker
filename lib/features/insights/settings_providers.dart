import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Read from --dart-define (empty if not supplied)
const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

/// Prefer using a proxy so the app never holds the key.
/// e.g. --dart-define=AI_PROXY_URL=https://<your>.vercel.app/api/insights
const aiProxyUrl = String.fromEnvironment('AI_PROXY_URL', defaultValue: '');

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
