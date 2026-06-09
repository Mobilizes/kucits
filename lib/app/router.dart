import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home/home_shell.dart';
import '../screens/timeline_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import 'dart:async';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool isAuthRoute =
          state.uri.path == '/login' ||
          state.uri.path == '/register' ||
          state.uri.path == '/reset-password';

      // If not logged in and not on auth route, go to login.
      if (!loggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and trying to access auth screens, go to home.
      if (loggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: <RouteBase>[
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Bottom Nav routes
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return HomeShell(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              // Timeline screen handles theme toggling, we'll need to adjust this in main.dart
              // For now, let's pass a dummy or use InheritedWidget later.
              return TimelineScreen(onToggleTheme: () {});
            },
          ),
          GoRoute(
            path: '/database',
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(
                body: Center(child: Text('Cat Database Screen - Coming Soon')),
              );
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(
                body: Center(child: Text('User Profile Screen - Coming Soon')),
              );
            },
          ),
        ],
      ),
    ],
  );
}
