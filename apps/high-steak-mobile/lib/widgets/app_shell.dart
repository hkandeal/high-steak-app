import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/feed_screen.dart';
import '../services/api_service.dart';
import '../navigation/post_editor_leave_guard.dart';
import '../theme/app_palette.dart';
import '../theme/theme_controller.dart';
import 'brand_background.dart';
import 'theme_toggle.dart';

class _ShellDestination {
  const _ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

List<_ShellDestination> _shellDestinations(AuthController auth) {
  final userId = auth.user?.id;
  final destinations = <_ShellDestination>[
    const _ShellDestination(
      path: '/feed',
      label: 'Feed',
      icon: Icons.local_fire_department_outlined,
      selectedIcon: Icons.local_fire_department,
    ),
  ];

  if (auth.hasScope('places:read')) {
    destinations.insert(
      1,
      const _ShellDestination(
        path: '/explore',
        label: 'Explore',
        icon: Icons.place_outlined,
        selectedIcon: Icons.place,
      ),
    );
  }

  if (auth.hasScope('bookmarks:read')) {
    destinations.add(
      const _ShellDestination(
        path: '/bookmarks',
        label: 'Saved',
        icon: Icons.bookmark_border,
        selectedIcon: Icons.bookmark,
      ),
    );
  }

  if (auth.hasScope('users:discover')) {
    destinations.add(
      const _ShellDestination(
        path: '/discover',
        label: 'Discover',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
      ),
    );
  }

  if (userId != null) {
    destinations.add(
      _ShellDestination(
        path: '/users/$userId',
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    );
  }

  return destinations;
}

int _selectedIndex(String path, List<_ShellDestination> destinations) {
  for (var i = 0; i < destinations.length; i++) {
    final destPath = destinations[i].path;
    if (path == destPath) return i;
    if (path.startsWith('/explore/') && destPath == '/explore') return i;
    if (destPath == '/feed' &&
        (path.startsWith('/posts/') || path == '/post/new')) {
      return i;
    }
    if (destPath.startsWith('/users/') && path.startsWith('/users/')) {
      return i;
    }
  }
  return 0;
}

bool _isRootShellRoute(String path, List<_ShellDestination> destinations) {
  for (final dest in destinations) {
    if (dest.path == path) return true;
    if (dest.path == '/explore' && path.startsWith('/explore/')) return true;
  }
  return path == '/notifications';
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.auth,
    required this.api,
    required this.themeController,
    required this.child,
  });

  final AuthController auth;
  final ApiService api;
  final ThemeController themeController;
  final Widget child;

  String _title(String path) {
    if (path == '/feed') return 'High Steaks';
    if (path == '/explore' || path.startsWith('/explore/')) return 'Explore';
    if (path == '/bookmarks') return 'Bookmarks';
    if (path == '/discover') return 'Discover';
    if (path == '/following') return 'Following';
    if (path == '/notifications') return 'Notifications';
    if (path == '/post/new') return 'New post';
    if (path.endsWith('/edit') && path.startsWith('/posts/')) return 'Edit post';
    if (path.startsWith('/posts/')) return 'Steak post';
    if (path.startsWith('/users/')) return 'Profile';
    return 'High Steaks';
  }

  bool _canCreatePost(String path) =>
      path == '/feed' && auth.hasScope('posts:write');

  Future<void> _navigateIfAllowed(
    BuildContext context,
    VoidCallback navigate,
  ) async {
    if (!await confirmPostEditorLeave(context)) return;
    if (context.mounted) navigate();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final palette = context.palette;
    final destinations = _shellDestinations(auth);
    final navIndex = _selectedIndex(path, destinations);
    final showBack = !_isRootShellRoute(path, destinations);

    return BrandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => _navigateIfAllowed(context, () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/feed');
                    }
                  }),
                )
              : null,
          title: Text(_title(path)),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
              icon: Icon(Icons.notifications_outlined, color: palette.gold),
            ),
            ThemeToggle(themeController: themeController),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: palette.gold),
              color: palette.charcoalLight,
              onSelected: (value) async {
                if (value == 'logout') {
                  if (!await confirmPostEditorLeave(context)) return;
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                } else if (value == 'profile') {
                  final userId = auth.user?.id;
                  if (userId != null) {
                    await _navigateIfAllowed(
                      context,
                      () => context.go('/users/$userId'),
                    );
                  }
                } else if (value == 'new-post') {
                  context.push('/post/new');
                } else if (value == 'bookmarks') {
                  await _navigateIfAllowed(context, () => context.go('/bookmarks'));
                } else if (value == 'discover') {
                  await _navigateIfAllowed(context, () => context.go('/discover'));
                } else if (value == 'following') {
                  await _navigateIfAllowed(context, () => context.go('/following'));
                } else if (value == 'explore') {
                  await _navigateIfAllowed(context, () => context.go('/explore'));
                } else if (value == 'notifications') {
                  context.push('/notifications');
                }
              },
              itemBuilder: (context) => [
                if (auth.hasScope('posts:write'))
                  const PopupMenuItem(
                    value: 'new-post',
                    child: Text('Rate a steak'),
                  ),
                if (auth.hasScope('places:read') &&
                    !destinations.any((d) => d.path == '/explore'))
                  const PopupMenuItem(
                    value: 'explore',
                    child: Text('Explore map'),
                  ),
                if (auth.hasScope('bookmarks:read') &&
                    !destinations.any((d) => d.path == '/bookmarks'))
                  const PopupMenuItem(
                    value: 'bookmarks',
                    child: Text('Bookmarks'),
                  ),
                if (auth.hasScope('users:discover') &&
                    !destinations.any((d) => d.path == '/discover'))
                  const PopupMenuItem(
                    value: 'discover',
                    child: Text('Find steak lovers'),
                  ),
                if (auth.hasScope('subscriptions:read'))
                  const PopupMenuItem(
                    value: 'following',
                    child: Text('Following'),
                  ),
                const PopupMenuItem(
                  value: 'notifications',
                  child: Text('Notifications'),
                ),
                if (auth.user?.id != null)
                  const PopupMenuItem(value: 'profile', child: Text('My profile')),
                const PopupMenuItem(value: 'logout', child: Text('Log out')),
              ],
            ),
          ],
        ),
        body: child,
        floatingActionButton: _canCreatePost(path)
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/post/new'),
                icon: const Icon(Icons.add),
                label: const Text('Rate steak'),
              )
            : null,
        bottomNavigationBar: destinations.length >= 2
            ? NavigationBar(
                selectedIndex: navIndex.clamp(0, destinations.length - 1),
                onDestinationSelected: (index) {
                  final destination = destinations[index].path;
                  if (destination == path) return;
                  _navigateIfAllowed(context, () => context.go(destination));
                },
                destinations: destinations
                    .map(
                      (dest) => NavigationDestination(
                        icon: Icon(dest.icon),
                        selectedIcon: Icon(dest.selectedIcon),
                        label: dest.label,
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
    );
  }
}

class FeedShellScreen extends StatelessWidget {
  const FeedShellScreen({super.key, required this.auth, required this.api});

  final AuthController auth;
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return FeedScreen(auth: auth, api: api);
  }
}
