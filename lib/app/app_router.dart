import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_finan/app/router_refresh.dart';
import 'package:mini_finan/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:mini_finan/features/auth/providers/auth_providers.dart';
import 'package:mini_finan/features/categories/presentation/categories_screen.dart';
import 'package:mini_finan/features/categories/presentation/rules_screen.dart';
import 'package:mini_finan/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mini_finan/features/more/presentation/more_screen.dart';
import 'package:mini_finan/features/transactions/presentation/add_transaction_screen.dart';
import 'package:mini_finan/features/transactions/presentation/import_csv_screen.dart';
import 'package:mini_finan/features/transactions/presentation/transactions_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  String? redirectLogic(BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;
    final loggingIn = state.matchedLocation == '/sign-in';
    if (user == null) {
      // not signed in → only allow /sign-in
      return loggingIn ? null : '/sign-in';
    } else {
      // signed in → kick away from /sign-in
      if (loggingIn) return '/dashboard';
      // otherwise allow
      return null;
    }
  }

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRefreshStreamProvider),
    ),
    redirect: redirectLogic,
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => SignInScreen()),
      GoRoute(
        path: '/transactions',
        builder: (ctx, st) {
          final startStr = st.uri.queryParameters['start'];
          final endStr = st.uri.queryParameters['end'];
          final start = startStr != null ? DateTime.parse(startStr) : null;
          final end = endStr != null ? DateTime.parse(endStr) : null;
          return TransactionsScreen(
            start: start,
            end: end,
          );
        },
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (_, __) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/more',
        builder: (_, __) => const MoreScreen(),
      ),
      GoRoute(
        path: '/import',
        builder: (_, __) => const ImportCsvScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/rules',
        builder: (_, __) => const RulesScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (ctx, state) => const DashboardScreen(),
      ),
    ],
  );
});
