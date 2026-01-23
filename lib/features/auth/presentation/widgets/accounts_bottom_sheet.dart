import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/auth/application/upgrade_account_controller.dart';
import 'package:mini_finan/features/auth/application/upgrade_account_state.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';
import 'package:mini_finan/features/auth/providers/auth_ui_providers.dart';

Future<void> showAccountsBottomSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AccountsSheet(),
  );
}

class _AccountsSheet extends ConsumerStatefulWidget {
  const _AccountsSheet();

  @override
  ConsumerState<_AccountsSheet> createState() => _AccountsSheetState();
}

class _AccountsSheetState extends ConsumerState<_AccountsSheet> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ProviderSubscription<UpgradeAccountState>? _upgradeSub;

  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();

    _upgradeSub = ref.listenManual<UpgradeAccountState>(
      upgradeAccountControllerProvider,
      (prev, next) {
        final prevStatus = prev?.status;
        if (prevStatus != UpgradeStatus.success &&
            next.status == UpgradeStatus.success) {
          Timer(const Duration(milliseconds: 900), () {
            if (!mounted) return;
            Navigator.of(context).maybePop();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _upgradeSub?.close();
    _closeTimer?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use userChangesProvider/isAnonymousProvider so it updates after linking
    // If you already created isAnonymousProvider in auth_ui_providers.dart, prefer it:
    final isAnon = ref.watch(isAnonymousProvider);

    // Label should also come from userChangesProvider via authLabelProvider
    final label = ref.watch(authLabelProvider);

    final state = ref.watch(upgradeAccountControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1) Accounts header
          Row(
            children: [
              const Text(
                'Accounts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Center content area only changes
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _centerContent(context, isAnon, state),
          ),
        ],
      ),
    );
  }

  Widget _centerContent(
    BuildContext context,
    bool isAnon,
    UpgradeAccountState state,
  ) {
    final ctrl = ref.read(upgradeAccountControllerProvider.notifier);

    if (!isAnon) {
      return Container(
          key: const ValueKey('already'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Already signed in with an account.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.logout_outlined,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.of(context).maybePop();
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                      },
                    ),
                  ),
                ],
              )
            ],
          ));
    }

    if (state.status == UpgradeStatus.loading) {
      // 4) progress
      return Container(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(vertical: 26),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (state.status == UpgradeStatus.success) {
      // 5/6) success in same spot
      return Container(
        key: const ValueKey('success'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              '✅ Sign up success!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              state.successEmail ?? '',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == UpgradeStatus.editing) {
      // 3) show form in same place
      return Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('form'),
          children: [
            if (state.error != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  state.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Enter email';
                if (!t.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                final t = v ?? '';
                if (t.isEmpty) return 'Enter password';
                if (t.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _emailCtrl.clear();
                      _passCtrl.clear();
                      ctrl.reset();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      await ctrl.signUpAndLink(
                        email: _emailCtrl.text,
                        password: _passCtrl.text,
                      );
                    },
                    child: const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2) Sign Up button in center
    return Container(
      key: const ValueKey('signup_button'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity, // ✅ forces finite width from sheet padding
        child: FilledButton(
          onPressed: () => ctrl.startEditing(),
          child: const Text('Sign Up'),
        ),
      ),
    );
  }
}
