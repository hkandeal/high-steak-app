import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/following_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/post_editor_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../services/api_service.dart';
import '../theme/app_scroll_behavior.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_shell.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../navigation/deep_link_service.dart';
import '../navigation/app_navigator.dart';
import '../utils/feed_layout_controller.dart';
import '../widgets/feed_layout_scope.dart';

GoRouter createAppRouter({
  required AuthController auth,
  required ApiService api,
  required ThemeController theme,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.initializing || theme.initializing) return null;

      final authRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation.startsWith('/reset-password');
      final onLanding = state.matchedLocation == '/';

      if (!auth.isAuthenticated) {
        if (authRoute || onLanding) return null;
        return '/login';
      }

      if (authRoute || onLanding) return '/feed';

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

      if (state.matchedLocation == '/bookmarks' &&
          !auth.hasScope('bookmarks:read')) {
        return '/feed';
      }

      if (state.matchedLocation.startsWith('/explore') &&
          !auth.hasScope('places:read')) {
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
        builder: (context, state) => RegisterScreen(
          auth: auth,
          api: api,
          themeController: theme,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          api: api,
          themeController: theme,
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
          api: api,
          themeController: theme,
        ),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
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
            path: '/bookmarks',
            builder: (context, state) => BookmarksScreen(auth: auth, api: api),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) =>
                NotificationsScreen(auth: auth, api: api),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => ExploreScreen(auth: auth, api: api),
          ),
          GoRoute(
            path: '/explore/:placeId',
            builder: (context, state) => ExploreScreen(
              auth: auth,
              api: api,
              placeId: state.pathParameters['placeId'],
            ),
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
            builder: (context, state) => CreatePostScreen(
              auth: auth,
              api: api,
              initialPlaceId: state.uri.queryParameters['placeId'],
            ),
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

class AuthBootstrap extends StatefulWidget {
  const AuthBootstrap({
    super.key,
    required this.auth,
    required this.api,
    required this.theme,
    required this.feedLayout,
  });

  final AuthController auth;
  final ApiService api;
  final ThemeController theme;
  final FeedLayoutController feedLayout;

  @override
  State<AuthBootstrap> createState() => _AuthBootstrapState();
}

class _AuthBootstrapState extends State<AuthBootstrap> with WidgetsBindingObserver {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = createAppRouter(auth: widget.auth, api: widget.api, theme: widget.theme);
    DeepLinkService.instance.attach(_router!);
    unawaited(DeepLinkService.instance.initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.auth.refreshSessionIfNeeded());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auth.initializing ||
        widget.theme.initializing ||
        widget.feedLayout.initializing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        theme: AppTheme.build(widget.theme.variant),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return FeedLayoutScope(
      notifier: widget.feedLayout,
      child: MaterialApp.router(
        title: 'High Steaks',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        theme: AppTheme.build(widget.theme.variant),
        routerConfig: _router!,
      ),
    );
  }
}
