import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_finan/services/firebase_providers.dart';

/// Stream of FirebaseAuth changes as AsyncValueUser?
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

/// Raw stream (not AsyncValue) – handy for go_router refresh
final authStreamRawProvider = Provider<Stream<User?>>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();
  Future<void> signOut() => _auth.signOut();
}

/// ✅ Reactive UID (null when signed out). Derived from authStateChangesProvider,
/// not from currentUser, so listeners rebuild on sign-in/out.
final authUidNullableProvider = Provider<String?>((ref) {
  final auth = ref.watch(authStateChangesProvider);
  return auth.maybeWhen(data: (u) => u?.uid, orElse: () => null);
});

/// Throws if no user – use when a UID is required (writes, etc.)
final authUidProvider = Provider<String>((ref) {
  final uid = ref.watch(authUidNullableProvider);
  if (uid == null) throw StateError('No user signed in');
  return uid;
});

/// Optional convenience
final isSignedInProvider =
    Provider<bool>((ref) => ref.watch(authUidNullableProvider) != null);
