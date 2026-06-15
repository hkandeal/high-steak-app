import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'router/app_router.dart';
import 'services/api_service.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  final auth = AuthController(api: api);
  final theme = ThemeController();
  await Future.wait([auth.initialize(), theme.initialize()]);
  runApp(AppRoot(auth: auth, api: api, theme: theme));
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
