import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_ui_providers.g.dart';

@riverpod
String authLabel(Ref ref) {
  final userAsync = ref.watch(userChangesProvider);

  return userAsync.maybeWhen(
    data: (User? u) {
      if (u == null) return 'Anonymous';
      if (u.isAnonymous) return 'Anonymous';
      final email = u.email?.trim();
      return (email != null && email.isNotEmpty) ? email : 'Account';
    },
    orElse: () => 'Anonymous',
  );
}

@riverpod
bool isAnonymous(Ref ref) {
  final userAsync = ref.watch(userChangesProvider);
  return userAsync.maybeWhen(
    data: (u) => (u?.isAnonymous ?? true),
    orElse: () => true,
  );
}
