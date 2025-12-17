import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_finan/features/auth/application/upgrade_account_state.dart';
import 'package:mini_finan/features/auth/application/upgrade_anonymous_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upgrade_account_controller.g.dart';

@riverpod
class UpgradeAccountController extends _$UpgradeAccountController {
  @override
  UpgradeAccountState build() => const UpgradeAccountState.idle();

  void startEditing() {
    state = state.copyWith(status: UpgradeStatus.editing, error: null);
  }

  void reset() {
    state = const UpgradeAccountState.idle();
  }

  Future<void> signUpAndLink({
    required String email,
    required String password,
  }) async {
    final e = email.trim();
    if (e.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: UpgradeStatus.editing,
        error: 'Email and password are required.',
      );
      return;
    }

    state = state.copyWith(status: UpgradeStatus.loading, error: null);

    try {
      final usecase = ref.read(upgradeAnonymousUsecaseProvider);
      final upgradedEmail = await usecase(email: e, password: password);

      state = state.copyWith(
        status: UpgradeStatus.success,
        successEmail: upgradedEmail,
        error: null,
      );
    } on FirebaseAuthException catch (err) {
      state = state.copyWith(
        status: UpgradeStatus.editing,
        error: _friendly(err),
      );
    } catch (err) {
      state = state.copyWith(
        status: UpgradeStatus.editing,
        error: err.toString(),
      );
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already in use. Try logging in instead.';
      case 'invalid-email':
        return 'Email format looks invalid.';
      case 'weak-password':
        return 'Password is too weak (try 6+ chars).';
      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';
      default:
        return e.message ?? 'Sign up failed.';
    }
  }
}
