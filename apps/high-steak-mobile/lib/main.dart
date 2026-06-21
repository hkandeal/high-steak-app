import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'constants/api_constraints.dart';
import 'router/app_router.dart';
import 'services/api_service.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await _loadImageConstraints(api);
  final auth = AuthController(api: api);
  final theme = ThemeController();
  await Future.wait([auth.initialize(), theme.initialize()]);
  runApp(AppRoot(auth: auth, api: api, theme: theme));
}

Future<void> _loadImageConstraints(ApiService api) async {
  try {
    final config = await api.fetchAppConfig();
    final maxMb = config['maxImageSizeMb'];
    if (maxMb is int) {
      ApiConstraints.applyRemoteConfig(maxMb);
    } else if (maxMb is num) {
      ApiConstraints.applyRemoteConfig(maxMb.toInt());
    }
  } catch (_) {
    // Keep build-time default when API is unreachable.
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({
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
    return ListenableBuilder(
      listenable: Listenable.merge([auth, theme]),
      builder: (context, _) {
        return AuthBootstrap(auth: auth, api: api, theme: theme);
      },
    );
  }
}
