import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth: whether AI mode is enabled for insights.
final insightsUseAiProvider = StateProvider<bool>((_) => false);
