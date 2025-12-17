import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_finan/features/auth/domain/firebase_auth_repository.dart';

class FirebaseAuthRepositoryImpl implements FirebaseAuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepositoryImpl(this._auth);
  @override
  Future<String> linkAnonymousWithEmail(
      {required String email, required String password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    if (!user.isAnonymous) throw StateError('User is already registered');

    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    await user.linkWithCredential(cred);
    await _auth.currentUser?.reload();

    final upgradedEmail = _auth.currentUser?.email?.trim();
    return (upgradedEmail != null && upgradedEmail.isNotEmpty)
        ? upgradedEmail
        : email.trim();
  }
}
