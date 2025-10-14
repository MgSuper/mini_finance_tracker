import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mini_finan/features/insights/insights_metrics.dart';

import 'package:mini_finan/services/firebase_providers.dart';

/// Provided via --dart-define=AI_PROXY_URL=https://<your-vercel-app>.vercel.app/api/insights
const String kAiProxyUrl = String.fromEnvironment('AI_PROXY_URL',
    defaultValue:
        'https://mini-finance-tracker-o6j71dmqk-supers-projects-f0402237.vercel.app/api/ai-insights');

/// Builds a compact "metrics" object your Vercel function expects
Map<String, dynamic> _buildMetricsJson(InsightsMetrics m) {
  // totals
  final totalIncome =
      m.incomeByCategory.values.fold<double>(0, (a, b) => a + b);
  final totalSpend =
      m.expenseByCategory.values.fold<double>(0, (a, b) => a + b);
  final net = totalIncome - totalSpend;

  // arrays with resolved category names
  final expenseByCategory = m.expenseByCategory.entries
      .map((e) => {
            'categoryId': e.key,
            'categoryName': m.catNameOf(e.key),
            'amount': e.value, // positive
          })
      .toList();

  final incomeByCategory = m.incomeByCategory.entries
      .map((e) => {
            'categoryId': e.key,
            'categoryName': m.catNameOf(e.key),
            'amount': e.value, // positive
          })
      .toList();

  final merchantSpend = m.merchantSpend.entries
      .map((e) => {
            'merchant': e.key,
            'amount': e.value, // positive
          })
      .toList();

  return {
    'summary': {
      'totalIncome': totalIncome,
      'totalSpend': totalSpend,
      'net': net,
    },
    'expenseByCategory': expenseByCategory,
    'incomeByCategory': incomeByCategory,
    'merchantSpend': merchantSpend,
  };
}

/// Calls your Vercel proxy with {metrics, model} and Firebase ID token.
/// Returns a list of 1–3 bullet strings parsed from { text }.
final monthlyInsightsAiProvider = FutureProvider<List<String>>((ref) async {
  if (kAiProxyUrl.isEmpty) return const <String>[];

  // Metrics
  final metrics = ref.read(insightsMetricsProvider);
  final metricsJson = _buildMetricsJson(metrics);

  // Optional model switch (hard-coded here; expose a setting later if you like)
  const model = 'gpt-4o-mini';

  // Firebase ID token for Authorization: Bearer <token>
  final auth = ref.read(firebaseAuthProvider);
  final token = await auth.currentUser?.getIdToken(true);
  print('token >>>>>>> $token');
  if (token == null) {
    // Not signed in -> your proxy will 401; return empty to keep UI calm
    return const <String>[];
  }

  final res = await http.post(
    Uri.parse(kAiProxyUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'metrics': metricsJson, 'model': model}),
  );

  if (res.statusCode == 401) {
    // Unauthorized from proxy – show nothing but don’t crash UI
    return const <String>[];
  }
  if (res.statusCode ~/ 100 != 2) {
    throw StateError('AI proxy error ${res.statusCode}: ${res.body}');
  }

  final decoded = jsonDecode(res.body);
  // Your endpoint returns { uid, text }
  final text = (decoded is Map && decoded['text'] is String)
      ? decoded['text'] as String
      : '';

  if (text.isEmpty) return const <String>[];

  // Split nicely into bullet-ish lines (keep it simple)
  final lines = text
      .split(RegExp(r'[\n•\-]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  // Cap to 3 succinct lines for UI
  return lines.take(3).toList();
});
