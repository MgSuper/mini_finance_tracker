import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_finan/features/auth/application/upgrade_anonymous_usecase.dart';
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
    return resultEmail;
  }
}

void main() {
  test('UpgradeAnonymousUsecase calls repository and return email', () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider
          .overrideWithValue(FakeAuthRepository(resultEmail: 'x@test.com'))
    ]);
    addTearDown(container.dispose);
    final usecase = container.read(upgradeAnonymousUsecaseProvider);
    final email = await usecase(email: 'x@test.com', password: '123456');
    expect(email, 'x@test.com');
  });
}
