import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_finan/features/auth/application/upgrade_account_controller.dart';
import 'package:mini_finan/features/auth/application/upgrade_account_state.dart';
import 'package:mini_finan/features/auth/domain/firebase_auth_repository.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';

class FakeAuthRepository implements FirebaseAuthRepository {
  FakeAuthRepository({this.resultEmail = 'x@test.com', this.throwError});
  final String resultEmail;
  final Object? throwError;
  @override
  Future<String> linkAnonymousWithEmail(
      {required String email, required String password}) async {
    if (throwError != null) throw throwError!;
    return email;
  }
}

void main() {
  test('Initial state is idle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(upgradeAccountControllerProvider);
    expect(state.status, UpgradeStatus.idle);
    expect(state.error, isNull);
  });

  test('empty email and password -> editing + validation error', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller =
        container.read(upgradeAccountControllerProvider.notifier);
    await controller.signUpAndLink(email: '   ', password: '');
    final state = container.read(upgradeAccountControllerProvider);
    expect(state.status, UpgradeStatus.editing);
    expect(state.error, 'Email and password are required.');
  });

  test('success -> success state + successEmail', () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(resultEmail: 'x@test.com'),
      ),
    ]);
    addTearDown(container.dispose);
    final controller =
        container.read(upgradeAccountControllerProvider.notifier);
    await controller.signUpAndLink(email: 'x@test.com', password: '123456');
    final state = container.read(upgradeAccountControllerProvider);
    expect(state.status, UpgradeStatus.success);
    expect(state.successEmail, 'x@test.com');
    expect(state.error, isNull);
  });

  test('FirebaseAuthException -> email-already-in-use + friendly message',
      () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          throwError: FirebaseAuthException(code: 'email-already-in-use'),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    final controller =
        container.read(upgradeAccountControllerProvider.notifier);
    await controller.signUpAndLink(email: 'x@test.com', password: '123456');
    final state = container.read(upgradeAccountControllerProvider);
    expect(state.status, UpgradeStatus.editing);
    expect(
        state.error, 'That email is already in use. Try logging in instead.');
  });

  test('unknown error -> editing + error.toString()', () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          throwError: Exception('boom'),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    final controller =
        container.read(upgradeAccountControllerProvider.notifier);
    await controller.signUpAndLink(email: 'x@test.com', password: '123456');
    final state = container.read(upgradeAccountControllerProvider);
    expect(state.status, UpgradeStatus.editing);
    expect(state.error, contains('boom'));
  });
}
