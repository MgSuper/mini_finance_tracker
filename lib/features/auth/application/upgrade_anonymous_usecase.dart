import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/domain/firebase_auth_repository.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upgrade_anonymous_usecase.g.dart';

class UpgradeAnonymousUsecase {
  final FirebaseAuthRepository _repository;
  UpgradeAnonymousUsecase(this._repository);

  Future<String> call({
    required String email,
    required String password,
  }) {
    return _repository.linkAnonymousWithEmail(
      email: email,
      password: password,
    );
  }
}

@riverpod
UpgradeAnonymousUsecase upgradeAnonymousUsecase(Ref ref) {
  return UpgradeAnonymousUsecase(ref.watch(authRepositoryProvider));
}
