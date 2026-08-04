import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_controller.dart';
import '../utils/constants.dart';
import '../screens/auth/account_status_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/terms_screen.dart';
import '../screens/branch_manager/branch_manager_home_shell.dart';
import '../screens/client/client_home_shell.dart';
import '../screens/driver/driver_home_shell.dart';
import '../screens/shared/splash_screen.dart';
import '../utils/theme.dart';

GoRouter buildRouter(AuthController authController) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authController,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/rejected',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          return AccountStatusScreen(
            icon: Icons.block_rounded,
            iconColor: AppColors.error,
            iconBackground: AppColors.errorContainer,
            title: l10n.rejectedTitle,
            message: l10n.rejectedMessage,
          );
        },
      ),
      GoRoute(
        path: '/suspended',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          return AccountStatusScreen(
            icon: Icons.pause_circle_outline_rounded,
            iconColor: AppColors.warning,
            iconBackground: AppColors.warningContainer,
            title: l10n.suspendedTitle,
            message: l10n.suspendedMessage,
          );
        },
      ),
      GoRoute(
        path: '/director-blocked',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          return AccountStatusScreen(
            icon: Icons.admin_panel_settings_outlined,
            iconColor: AppColors.secondary,
            iconBackground: AppColors.secondaryContainer,
            title: l10n.directorNotSupportedTitle,
            message: l10n.directorNotSupportedMessage,
          );
        },
      ),
      GoRoute(path: '/client', builder: (context, state) => const ClientHomeShell()),
      GoRoute(
        path: '/branch',
        builder: (context, state) => const BranchManagerHomeShell(),
      ),
      GoRoute(path: '/driver', builder: (context, state) => const DriverHomeShell()),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      const publicRoutes = {'/login', '/register', '/terms'};

      if (authController.status == AuthStatus.loading) {
        return loc == '/splash' ? null : '/splash';
      }

      if (authController.status == AuthStatus.signedOut) {
        if (publicRoutes.contains(loc)) return null;
        return '/login';
      }

      // Signed in from here on.
      final profile = authController.profile;
      if (profile == null) {
        // Auth session exists but the users row hasn't been readable yet
        // (e.g. transient error) — keep on splash rather than guessing.
        return loc == '/splash' ? null : '/splash';
      }

      if (profile.role == UserRole.companyDirector) {
        // Out of scope for this app entirely — reject immediately and sign
        // out so no director session lingers on a mobile device.
        Future.microtask(() => authController.signOut());
        return loc == '/director-blocked' ? null : '/director-blocked';
      }

      switch (profile.accountStatus) {
        case AccountStatus.pendingApproval:
          return loc == '/pending-approval' ? null : '/pending-approval';
        case AccountStatus.rejected:
          return loc == '/rejected' ? null : '/rejected';
        case AccountStatus.suspended:
          return loc == '/suspended' ? null : '/suspended';
        case AccountStatus.active:
          final homeRoute = switch (profile.role) {
            UserRole.client => '/client',
            UserRole.branchManager => '/branch',
            UserRole.driver => '/driver',
            UserRole.companyDirector => '/director-blocked',
          };
          final activeRoutes = {'/client', '/branch', '/driver'};
          if (activeRoutes.contains(loc)) return null;
          if (publicRoutes.contains(loc) || loc == '/splash') return homeRoute;
          return null;
      }
    },
  );
}
