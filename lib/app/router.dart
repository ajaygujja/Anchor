import 'dart:async';

import 'package:anchor/app/splash_page.dart';
import 'package:anchor/features/auth/bloc/auth_bloc.dart';
import 'package:anchor/features/auth/view/sign_in_page.dart';
import 'package:anchor/features/dashboard/view/dashboard_page.dart';
import 'package:anchor/features/manage_habits/view/manage_habits_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Route locations. String constants keep redirect logic and route
/// definitions in sync.
abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const dashboard = '/';
  static const manage = '/manage';
}

/// Builds the app router with an auth-driven redirect.
///
/// The redirect is the single gate: `unknown` → splash, unauthenticated →
/// sign-in, authenticated → dashboard. go_router keeps the browser URL and
/// back button correct (spec §8.3).
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final location = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return location == Routes.splash ? null : Routes.splash;
      }
      if (status == AuthStatus.unauthenticated) {
        return location == Routes.signIn ? null : Routes.signIn;
      }
      if (location == Routes.signIn || location == Routes.splash) {
        return Routes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: Routes.manage,
        builder: (context, state) => const ManageHabitsPage(),
      ),
    ],
  );
}

/// Adapts a [Stream] into a [Listenable] so go_router re-evaluates its
/// redirect whenever auth state changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
