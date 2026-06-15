import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_controller.dart';
import '../constants/api_constraints.dart';
import '../controllers/paginated_list_controller.dart';
import '../models/steak_post.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/post_image_picker.dart';
import '../utils/profile_validation.dart';
import '../widgets/auth_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/paginated_list_view.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userId,
    required this.auth,
    required this.api,
  });

  final String userId;
  final AuthController auth;
  final ApiService api;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserPublicProfile? _profile;
  bool _loadingProfile = true;
  String? _profileError;
  PaginatedListController<SteakPost>? _posts;

  bool _editing = false;
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _avatarPicker = ImagePicker();
  XFile? _avatarFile;
  bool _pickingAvatar = false;
  bool _savingProfile = false;

  bool get _isOwnProfile => widget.auth.user?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _posts = PaginatedListController<SteakPost>(
      (page) => widget.api.fetchUserPosts(
        widget.auth.token!,
        widget.userId,
        page: page,
      ),
    );
    _loadProfile();
    _posts!.reload();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _posts?.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await widget.api.fetchUserProfile(
        widget.auth.token!,
        widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _loadingProfile = false;
      });
    }
  }

  void _startEditing() {
    final user = widget.auth.user;
    if (user == null) return;
    _displayName.text = user.displayName;
    _email.text = user.email;
    setState(() {
      _editing = true;
      _avatarFile = null;
      _profileError = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _avatarFile = null;
      _profileError = null;
    });
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar) return;
    setState(() {
      _pickingAvatar = true;
      _profileError = null;
    });

    try {
      final picked = await pickAvatarImage(_avatarPicker);
      if (!mounted) return;
      if (picked == null) {
        setState(() => _pickingAvatar = false);
        return;
      }

      final length = await picked.length();
      if (length > ApiConstraints.maxImageBytes) {
        setState(() {
          _pickingAvatar = false;
          _profileError =
              'Avatar must be ${ApiConstraints.maxImageMb} MB or smaller.';
        });
        return;
      }

      setState(() {
        _avatarFile = picked;
        _pickingAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickingAvatar = false;
        _profileError = pickerErrorMessage(e);
      });
    }
  }

  Future<void> _saveProfile() async {
    final validationError = validateProfileForm(
      displayName: _displayName.text,
      email: _email.text,
      hasNewAvatar: _avatarFile != null,
      avatarBytes: _avatarFile != null ? await _avatarFile!.length() : 0,
    );
    if (validationError != null) {
      setState(() => _profileError = validationError);
      return;
    }

    setState(() {
      _savingProfile = true;
      _profileError = null;
    });

    try {
      final result = await widget.api.updateProfile(
        widget.auth.token!,
        displayName: _displayName.text.trim(),
        email: _email.text.trim(),
        avatar: _avatarFile,
      );
      await widget.auth.applySessionUpdate(result.token);
      if (!mounted) return;
      setState(() {
        _profile = _profile?.copyWith(
          displayName: result.user.displayName,
          avatarUrl: result.user.avatarUrl,
        ) ??
            UserPublicProfile(
              id: result.user.id,
              username: result.user.username,
              displayName: result.user.displayName,
              avatarUrl: result.user.avatarUrl,
              postCount: _profile?.postCount ?? 0,
              subscribed: false,
            );
        _editing = false;
        _avatarFile = null;
        _savingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _savingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile && _profile == null) {
      return const LoadingState(message: 'Loading profile…');
    }

    if (_profileError != null && _profile == null) {
      return ErrorState(message: _profileError!, onRetry: _loadProfile);
    }

    if (_profile == null) {
      return const ErrorState(message: 'Profile not found');
    }

    final profile = _profile!;
    final theme = Theme.of(context);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.cardBorderStrong),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.gold.withValues(alpha: 0.1),
                  palette.cardBg,
                ],
              ),
            ),
            child: _editing
                ? _ProfileEditForm(
                    displayName: _displayName,
                    email: _email,
                    avatarFile: _avatarFile,
                    currentAvatarUrl: profile.avatarUrl,
                    displayNameLabel: profile.displayName,
                    pickingAvatar: _pickingAvatar,
                    saving: _savingProfile,
                    onPickAvatar: _pickAvatar,
                    onCancel: _cancelEditing,
                    onSave: _saveProfile,
                  )
                : Row(
                    children: [
                      UserAvatar(
                        displayName: profile.displayName,
                        avatarUrl: profile.avatarUrl,
                        radius: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${profile.username}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: palette.gold),
                            ),
                            const SizedBox(height: 10),
                            _StatChip(
                              icon: Icons.local_fire_department_outlined,
                              label: '${profile.postCount} posts',
                              palette: palette,
                            ),
                          ],
                        ),
                      ),
                      if (_isOwnProfile)
                        IconButton(
                          tooltip: 'Edit profile',
                          onPressed: _startEditing,
                          icon: Icon(Icons.edit_outlined, color: palette.gold),
                        ),
                    ],
                  ),
          ),
        ),
        if (_profileError != null && _profile != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AuthErrorBanner(message: _profileError!),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            _isOwnProfile ? 'Your steaks' : 'Steaks',
            style: theme.textTheme.titleMedium?.copyWith(color: palette.creamMuted),
          ),
        ),
        Expanded(
          child: PaginatedListView(
            controller: _posts!,
            emptyMessage: _isOwnProfile
                ? "You haven't posted yet."
                : 'No public posts yet.',
            emptyIcon: Icons.restaurant_outlined,
            itemBuilder: (context, item) => PostCard(post: item),
          ),
        ),
      ],
    );
  }
}

class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm({
    required this.displayName,
    required this.email,
    required this.avatarFile,
    required this.currentAvatarUrl,
    required this.displayNameLabel,
    required this.pickingAvatar,
    required this.saving,
    required this.onPickAvatar,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController displayName;
  final TextEditingController email;
  final XFile? avatarFile;
  final String? currentAvatarUrl;
  final String displayNameLabel;
  final bool pickingAvatar;
  final bool saving;
  final VoidCallback onPickAvatar;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarPreview(
              avatarFile: avatarFile,
              currentAvatarUrl: currentAvatarUrl,
              displayName: displayNameLabel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pickingAvatar || saving ? null : onPickAvatar,
                icon: pickingAvatar
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: palette.gold),
                      )
                    : const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(avatarFile == null ? 'Change photo' : 'Replace photo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: displayName,
          decoration: const InputDecoration(labelText: 'Display name'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Saving…' : 'Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.avatarFile,
    required this.currentAvatarUrl,
    required this.displayName,
  });

  final XFile? avatarFile;
  final String? currentAvatarUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (avatarFile != null) {
      final path = avatarFile!.path;
      if (!kIsWeb && path.isNotEmpty) {
        return CircleAvatar(
          radius: 36,
          backgroundImage: FileImage(File(path)),
        );
      }
      return FutureBuilder<List<int>>(
        future: avatarFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircleAvatar(
              radius: 36,
              backgroundColor: context.palette.charcoalLight,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return CircleAvatar(
            radius: 36,
            backgroundImage: MemoryImage(Uint8List.fromList(snapshot.data!)),
          );
        },
      );
    }

    return UserAvatar(
      displayName: displayName,
      avatarUrl: currentAvatarUrl,
      radius: 36,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.cream,
            ),
          ),
        ],
      ),
    );
  }
}
