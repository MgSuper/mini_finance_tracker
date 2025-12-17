import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:mini_finan/features/insights/insights_metrics.dart';
import 'package:mini_finan/features/insights/settings_providers.dart';
import 'package:mini_finan/features/auth/providers/firebase_providers.dart';

final insightsAiProvider = FutureProvider<String?>((ref) async {
  // Check if AI mode is enabled
  final useAi = ref.watch(useAiInsightsProvider);
  if (!useAi) return null;

  // Watch reactive metrics
  final metricsAsync = ref.watch(insightsMetricsProvider);
  final metrics = metricsAsync.valueOrNull;
  if (metrics == null || metrics.isEmpty) {
    return null; // still loading
  }

  // Prefer proxy (recommended)
  final proxy = aiProxyUrl.trim();

  if (proxy.isNotEmpty) {
    final auth = ref.read(firebaseAuthProvider);
    final idToken = await auth.currentUser?.getIdToken(true);

    final resp = await http.post(
      Uri.parse(proxy),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'metrics': metrics,
        'model': 'gpt-4o-mini',
      }),
    );
    debugPrint('[AI] proxy status=${resp.statusCode} body=${resp.body}');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = (data['text'] as String?)?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }
    // Proxy failed
    return null;
  }

  // No proxy → fallback to direct OpenAI
  final apiKey = openAiApiKey;
  if (apiKey.isEmpty) return null;

  final prompt = '''
You are a budgeting assistant. Summarize the user's monthly finances in 2–3 short, plain sentences.
Prefer concrete numbers and comparisons month-over-month. Avoid promises or advice.
JSON:
${jsonEncode(metrics)}
''';
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

  final resp = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.3,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a concise financial summarizer.'
        },
        {'role': 'user', 'content': prompt},
      ],
    }),
  );

  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final text =
        (data['choices'] as List).first['message']['content'] as String;
    return text.trim();
  }
  return null;
});
