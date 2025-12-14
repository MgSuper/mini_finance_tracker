import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/app/app_router.dart';
import 'package:mini_finan/app/auth_sync.dart';
import 'package:mini_finan/app/app_theme.dart';
import 'package:mini_finan/app/providers/theme_mode_provider.dart';

class FinanceAIApp extends ConsumerWidget {
  const FinanceAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    return AuthSync(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'FinanceAI',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: router,
      ),
    );
  }
}
