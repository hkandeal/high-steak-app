import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/create_post_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/following_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/login_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/post_editor_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_shell.dart';

GoRouter createAppRouter({
  required AuthController auth,
  required ApiService api,
  required ThemeController theme,
}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.initializing || theme.initializing) return null;

      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final onLanding = state.matchedLocation == '/';

      if (!auth.isAuthenticated) {
        if (loggingIn || onLanding) return null;
        return '/login';
      }

      if (loggingIn || onLanding) return '/feed';

      if (state.matchedLocation == '/post/new' &&
          !auth.hasScope('posts:write')) {
        return '/feed';
      }

      if (state.matchedLocation.contains('/edit') &&
          state.matchedLocation.startsWith('/posts/') &&
          !auth.hasScope('posts:write')) {
        return '/feed';
      }

      if (state.matchedLocation == '/discover' &&
          !auth.hasScope('users:discover')) {
        return '/feed';
      }

      if (state.matchedLocation == '/following' &&
          !auth.hasScope('subscriptions:read')) {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => LandingScreen(themeController: theme),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(auth: auth, themeController: theme),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(auth: auth, themeController: theme),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          auth: auth,
          api: api,
          themeController: theme,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/feed',
            builder: (context, state) => FeedShellScreen(auth: auth, api: api),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => DiscoverScreen(auth: auth, api: api),
          ),
          GoRoute(
            path: '/following',
            builder: (context, state) => FollowingScreen(auth: auth, api: api),
          ),
          GoRoute(
            path: '/post/new',
            builder: (context, state) => CreatePostScreen(auth: auth, api: api),
          ),
          GoRoute(
            path: '/posts/:postId',
            builder: (context, state) => PostDetailScreen(
              postId: state.pathParameters['postId']!,
              auth: auth,
              api: api,
            ),
          ),
          GoRoute(
            path: '/posts/:postId/edit',
            builder: (context, state) => PostEditorScreen(
              postId: state.pathParameters['postId'],
              auth: auth,
              api: api,
            ),
          ),
          GoRoute(
            path: '/users/:userId',
            builder: (context, state) => ProfileScreen(
              userId: state.pathParameters['userId']!,
              auth: auth,
              api: api,
            ),
          ),
        ],
      ),
    ],
  );
}

class AuthBootstrap extends StatelessWidget {
  const AuthBootstrap({
    super.key,
    required this.auth,
    required this.api,
    required this.theme,
  });

  final AuthController auth;
  final ApiService api;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    if (auth.initializing || theme.initializing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(theme.variant),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'High Steak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(theme.variant),
      routerConfig: createAppRouter(auth: auth, api: api, theme: theme),
    );
  }
}
