import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_palette.dart';
import '../theme/theme_controller.dart';
import '../widgets/brand_background.dart';
import '../widgets/theme_toggle.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return BrandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: [
            ThemeToggle(themeController: themeController),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.accentSelectedBg,
                    border: Border.all(color: palette.cardBorderStrong),
                    boxShadow: [
                      BoxShadow(
                        color: palette.flameGlow,
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🥩', style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 24),
                Text('High Steak', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 12),
                Text(
                  'Rate steak meals. Share photos. Join the grill.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.creamMuted,
                    fontSize: 17,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Log in'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Create account'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
