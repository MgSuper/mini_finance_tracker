enum UpgradeStatus { idle, editing, loading, success }

class UpgradeAccountState {
  final UpgradeStatus status;
  final String? successEmail;
  final String? error;

  const UpgradeAccountState({
    required this.status,
    this.successEmail,
    this.error,
  });

  const UpgradeAccountState.idle() : this(status: UpgradeStatus.idle);

  UpgradeAccountState copyWith({
    UpgradeStatus? status,
    String? successEmail,
    String? error,
  }) {
    return UpgradeAccountState(
      status: status ?? this.status,
      successEmail: successEmail ?? this.successEmail,
      error: error,
    );
  }
}
