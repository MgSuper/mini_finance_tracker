import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/data/firebase_auth_repository_impl.dart';
import 'package:mini_finan/features/auth/domain/firebase_auth_repository.dart';
import 'package:mini_finan/features/auth/providers/firebase_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// Repository (interface -> Firebase implementation)
@riverpod
FirebaseAuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepositoryImpl(ref.watch(firebaseAuthProvider));
}

/// Stream: auth state changes (sign-in/out)
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

/// Stream: user changes (email/isAnonymous changes)
@riverpod
Stream<User?> userChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
}

/// UID (nullable)
@riverpod
String? authUidNullable(Ref ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  return userAsync.maybeWhen(data: (u) => u?.uid, orElse: () => null);
}

final authRefreshStreamProvider = Provider<Stream<User?>>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// UID (required)
@riverpod
String authUid(Ref ref) {
  final uid = ref.watch(authUidNullableProvider);
  if (uid == null) throw StateError('No user signed in');
  return uid;
}

@riverpod
bool isSignedIn(Ref ref) {
  return ref.watch(authUidNullableProvider) != null;
}

/// A small controller wrapper for imperative calls (optional)
@riverpod
AuthController authController(Ref ref) {
  return AuthController(ref);
}

class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
