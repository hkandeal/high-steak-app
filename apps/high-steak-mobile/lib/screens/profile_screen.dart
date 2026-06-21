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
import '../widgets/email_notification_settings.dart';
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
  final _avatarPicker = ImagePicker();
  XFile? _avatarFile;
  bool _pickingAvatar = false;
  bool _savingProfile = false;
  bool _followBusy = false;
  bool _deletionRequested = false;
  bool _deletionBusy = false;

  bool get _isOwnProfile => widget.auth.user?.id == widget.userId;

  bool get _isStaff =>
      widget.auth.user?.hasRole('ADMIN') == true ||
      widget.auth.user?.hasRole('MODERATOR') == true;

  bool get _canFollow =>
      !_isOwnProfile && widget.auth.hasScope('subscriptions:write');

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
    setState(() {
      _editing = true;
      _avatarFile = null;
      _profileError = null;
      _deletionRequested = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _avatarFile = null;
      _profileError = null;
      _deletionRequested = false;
    });
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar) return;
    setState(() {
      _pickingAvatar = true;
      _profileError = null;
    });

    try {
      final picked = await pickAvatarImageInteractive(context, _avatarPicker);
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

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || !_canFollow || _followBusy) return;

    setState(() => _followBusy = true);
    try {
      if (profile.subscribed) {
        await widget.api.unsubscribeFromUser(widget.auth.token!, profile.id);
      } else {
        await widget.api.subscribeToUser(widget.auth.token!, profile.id);
      }
      if (!mounted) return;
      setState(() {
        _profile = profile.copyWith(subscribed: !profile.subscribed);
        _followBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _followBusy = false;
      });
    }
  }

  Future<void> _requestAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'We will email you a confirmation link. Your account stays active until you confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send email'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deletionBusy = true;
      _profileError = null;
    });
    try {
      await widget.api.requestAccountDeletion(widget.auth.token!);
      if (!mounted) return;
      setState(() {
        _deletionRequested = true;
        _deletionBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _deletionBusy = false;
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
    final userEmail = widget.auth.user?.email ?? '';

    if (_editing) {
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_profileError != null) ...[
              AuthErrorBanner(message: _profileError!),
              const SizedBox(height: 12),
            ],
            Container(
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
              child: _ProfileEditForm(
                displayName: _displayName,
                email: userEmail,
                avatarFile: _avatarFile,
                currentAvatarUrl: profile.avatarUrl,
                displayNameLabel: profile.displayName,
                pickingAvatar: _pickingAvatar,
                saving: _savingProfile,
                deletionBusy: _deletionBusy,
                deletionRequested: _deletionRequested,
                showDeletion: !_isStaff,
                auth: widget.auth,
                api: widget.api,
                onPickAvatar: _pickAvatar,
                onCancel: _cancelEditing,
                onSave: _saveProfile,
                onRequestDeletion: _requestAccountDeletion,
              ),
            ),
          ],
        ),
      );
    }

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
            child: Row(
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
                  )
                else if (_canFollow)
                  FilledButton.tonal(
                    onPressed: _followBusy ? null : _toggleFollow,
                    child: Text(
                      _followBusy
                          ? '…'
                          : profile.subscribed
                              ? 'Following'
                              : 'Follow',
                    ),
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
            itemBuilder: (context, item) => PostCard(
              post: item,
              auth: widget.auth,
              api: widget.api,
              showBookmark: widget.auth.hasScope('bookmarks:write'),
              showOwnerActions: _isOwnProfile,
              onDeleted: () => _posts!.removeItem((post) => post.id == item.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileEditForm extends StatefulWidget {
  const _ProfileEditForm({
    required this.displayName,
    required this.email,
    required this.avatarFile,
    required this.currentAvatarUrl,
    required this.displayNameLabel,
    required this.pickingAvatar,
    required this.saving,
    required this.deletionBusy,
    required this.deletionRequested,
    required this.showDeletion,
    required this.auth,
    required this.api,
    required this.onPickAvatar,
    required this.onCancel,
    required this.onSave,
    required this.onRequestDeletion,
  });

  final TextEditingController displayName;
  final String email;
  final XFile? avatarFile;
  final String? currentAvatarUrl;
  final String displayNameLabel;
  final bool pickingAvatar;
  final bool saving;
  final bool deletionBusy;
  final bool deletionRequested;
  final bool showDeletion;
  final AuthController auth;
  final ApiService api;
  final VoidCallback onPickAvatar;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onRequestDeletion;

  @override
  State<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<_ProfileEditForm> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void didUpdateWidget(_ProfileEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email && _emailController.text != widget.email) {
      _emailController.text = widget.email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      alignLabelWithHint: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _AvatarPickerCard(
            avatarFile: widget.avatarFile,
            currentAvatarUrl: widget.currentAvatarUrl,
            displayName: widget.displayNameLabel,
            picking: widget.pickingAvatar,
            disabled: widget.saving,
            onTap: widget.onPickAvatar,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Display name',
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.creamMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.displayName,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(hint: 'How you appear on posts'),
        ),
        const SizedBox(height: 16),
        Text(
          'Email',
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.creamMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          readOnly: true,
          enableInteractiveSelection: true,
          style: theme.textTheme.bodyLarge?.copyWith(color: palette.creamMuted),
          decoration: _fieldDecoration(),
        ),
        const SizedBox(height: 6),
        Text(
          'Email cannot be changed here.',
          style: theme.textTheme.bodySmall?.copyWith(color: palette.creamMuted),
        ),
        const SizedBox(height: 24),
        EmailNotificationSettings(auth: widget.auth, api: widget.api),
        const SizedBox(height: 24),
        if (widget.showDeletion) ...[
          Divider(color: palette.cardBorder),
          const SizedBox(height: 16),
          Text(
            'Danger zone',
            style: theme.textTheme.titleMedium?.copyWith(color: palette.errorText),
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your account and all your data.',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.creamMuted),
          ),
          const SizedBox(height: 12),
          if (widget.deletionRequested)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.accentSelectedBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Text(
                'Check your email for a confirmation link to finish deleting your account.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: widget.deletionBusy || widget.saving ? null : widget.onRequestDeletion,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.errorText,
                side: BorderSide(color: palette.errorText.withValues(alpha: 0.5)),
              ),
              icon: widget.deletionBusy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.errorText,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined, size: 18),
              label: Text(widget.deletionBusy ? 'Sending…' : 'Delete account'),
            ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.saving ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: widget.saving ? null : widget.onSave,
                child: Text(widget.saving ? 'Saving…' : 'Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarPickerCard extends StatelessWidget {
  const _AvatarPickerCard({
    required this.avatarFile,
    required this.currentAvatarUrl,
    required this.displayName,
    required this.picking,
    required this.disabled,
    required this.onTap,
  });

  final XFile? avatarFile;
  final String? currentAvatarUrl;
  final String displayName;
  final bool picking;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: disabled || picking ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.cardBorderStrong),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _AvatarPreview(
                avatarFile: avatarFile,
                currentAvatarUrl: currentAvatarUrl,
                displayName: displayName,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.charcoal, width: 2),
                  ),
                  child: picking
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.charcoal,
                          ),
                        )
                      : Icon(Icons.photo_camera_outlined, size: 18, color: palette.charcoal),
                ),
              ),
            ],
          ),
        ),
      ),
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
          radius: 48,
          backgroundImage: FileImage(File(path)),
        );
      }
      return FutureBuilder<List<int>>(
        future: avatarFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircleAvatar(
              radius: 48,
              backgroundColor: context.palette.charcoalLight,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return CircleAvatar(
            radius: 48,
            backgroundImage: MemoryImage(Uint8List.fromList(snapshot.data!)),
          );
        },
      );
    }

    return UserAvatar(
      displayName: displayName,
      avatarUrl: currentAvatarUrl,
      radius: 48,
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
