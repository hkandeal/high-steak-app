import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../models/notification_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

typedef PreferenceKey = String;

class _PreferenceTile {
  const _PreferenceTile({
    required this.key,
    required this.icon,
    required this.label,
    required this.description,
    this.master = false,
  });

  final PreferenceKey key;
  final IconData icon;
  final String label;
  final String description;
  final bool master;
}

const _preferenceTiles = [
  _PreferenceTile(
    key: 'emailEnabled',
    icon: Icons.mail_outline,
    label: 'Email from High Steaks',
    description: 'Master switch for all notification emails.',
    master: true,
  ),
  _PreferenceTile(
    key: 'commentEmail',
    icon: Icons.chat_bubble_outline,
    label: 'New comments',
    description: 'When someone comments on your posts.',
  ),
  _PreferenceTile(
    key: 'followerEmail',
    icon: Icons.group_outlined,
    label: 'New followers',
    description: 'When someone follows you.',
  ),
  _PreferenceTile(
    key: 'moderationEmail',
    icon: Icons.shield_outlined,
    label: 'Moderation updates',
    description: 'When a moderator hides or restores your posts.',
  ),
  _PreferenceTile(
    key: 'welcomeEmail',
    icon: Icons.celebration_outlined,
    label: 'Welcome email',
    description: 'Sent once when you create your account.',
  ),
];

class EmailNotificationSettings extends StatefulWidget {
  const EmailNotificationSettings({
    super.key,
    required this.auth,
    required this.api,
  });

  final AuthController auth;
  final ApiService api;

  @override
  State<EmailNotificationSettings> createState() =>
      _EmailNotificationSettingsState();
}

class _EmailNotificationSettingsState extends State<EmailNotificationSettings> {
  NotificationPreferences? _prefs;
  bool _loading = true;
  String? _error;
  String? _savingKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.auth.token;
    if (token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await widget.api.fetchNotificationPreferences(token);
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _valueFor(PreferenceKey key) {
    final prefs = _prefs;
    if (prefs == null) return false;
    return switch (key) {
      'emailEnabled' => prefs.emailEnabled,
      'welcomeEmail' => prefs.welcomeEmail,
      'commentEmail' => prefs.commentEmail,
      'followerEmail' => prefs.followerEmail,
      'moderationEmail' => prefs.moderationEmail,
      _ => false,
    };
  }

  Future<void> _toggle(PreferenceKey key) async {
    final token = widget.auth.token;
    final prefs = _prefs;
    if (token == null || prefs == null || _savingKey != null) return;

    setState(() {
      _savingKey = key;
      _error = null;
    });
    try {
      final updated = await widget.api.updateNotificationPreferences(
        token,
        {key: !_valueFor(key)},
      );
      if (!mounted) return;
      setState(() => _prefs = updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final masterEnabled = _valueFor('emailEnabled');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email notifications',
          style: theme.textTheme.titleMedium?.copyWith(color: palette.gold),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose which emails we send you.',
          style: theme.textTheme.bodySmall?.copyWith(color: palette.creamMuted),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: palette.errorText)),
          )
        else if (_prefs != null) ...[
          for (final tile in _preferenceTiles)
            _PreferenceRow(
              tile: tile,
              value: _valueFor(tile.key),
              enabled: tile.master || masterEnabled,
              saving: _savingKey == tile.key,
              onChanged: () => _toggle(tile.key),
            ),
        ],
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.tile,
    required this.value,
    required this.enabled,
    required this.saving,
    required this.onChanged,
  });

  final _PreferenceTile tile;
  final bool value;
  final bool enabled;
  final bool saving;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          secondary: Icon(tile.icon, color: palette.gold, size: 22),
          title: Text(
            tile.label,
            style: TextStyle(
              fontWeight: tile.master ? FontWeight.w600 : FontWeight.w500,
              color: enabled ? palette.cream : palette.creamMuted,
            ),
          ),
          subtitle: Text(
            tile.description,
            style: TextStyle(fontSize: 13, color: palette.creamMuted),
          ),
          value: value,
          onChanged: enabled && !saving ? (_) => onChanged() : null,
        ),
      ),
    );
  }
}
