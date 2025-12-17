abstract class FirebaseAuthRepository {
  Future<String> linkAnonymousWithEmail({
    required String email,
    required String password,
  });
}
