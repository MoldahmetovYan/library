import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/book.dart';
import '../pages/admin/admin_home_page.dart';
import '../pages/book_detail_page.dart';
import '../pages/book_list_page.dart';
import '../pages/favorites_page.dart';
import '../pages/home_shell.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/register_page.dart';
import '../pages/settings/about_page.dart';
import '../pages/settings/realtime_page.dart';
import '../pages/settings/settings_page.dart';
import '../providers/user_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(
    userProvider.select((state) => state.user),
  );
  final authNotifier = ref.watch(userProvider.notifier);

  return GoRouter(
    initialLocation: currentUser == null ? '/login' : '/books',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      final goingAdmin = state.matchedLocation == '/admin';

      if (!isLoggedIn && !(loggingIn || registering)) {
        return '/login';
      }
      if (isLoggedIn && (loggingIn || registering)) {
        return '/books';
      }
      final role = currentUser?.role;
      if (goingAdmin && role != 'ROLE_ADMIN') {
        return '/books';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/books',
                name: 'books',
                builder: (context, state) => const BookListPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    name: 'book-detail',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _MissingBookScreen();
                      }
                      final book = state.extra is Book ? state.extra as Book : null;
                      return BookDetailPage(bookId: id, initialBook: book);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: 'favorites',
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'about',
                    name: 'about',
                    builder: (context, state) => const AboutPage(),
                  ),
                  GoRoute(
                    path: 'realtime',
                    name: 'realtime',
                    builder: (context, state) => const RealtimePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminHomePage(),
      ),
    ],
  );
});

class _MissingBookScreen extends StatelessWidget {
  const _MissingBookScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Информация о книге недоступна'),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
