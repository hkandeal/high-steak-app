import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../constants/api_constraints.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../widgets/auth_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_search_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.auth,
    required this.api,
  });

  final AuthController auth;
  final ApiService api;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';
  List<UserPublicProfile> _results = [];
  bool _loading = false;
  String? _error;
  String? _pendingUserId;

  bool get _canFollow => widget.auth.hasScope('subscriptions:write');

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_onQueryChanged);
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = _query.text.trim());
      _search();
    });
  }

  Future<void> _search() async {
    final q = _debouncedQuery;
    if (q.length < ApiConstraints.searchQueryMin) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await widget.api.searchUsers(widget.auth.token!, q);
      if (!mounted) return;
      setState(() {
        _results = results;
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

  Future<void> _toggleFollow(UserPublicProfile user) async {
    if (!_canFollow || _pendingUserId != null) return;

    setState(() {
      _pendingUserId = user.id;
      _error = null;
    });

    try {
      if (user.subscribed) {
        await widget.api.unsubscribeFromUser(widget.auth.token!, user.id);
      } else {
        await widget.api.subscribeToUser(widget.auth.token!, user.id);
      }
      if (!mounted) return;
      setState(() {
        _results = _results
            .map((item) => item.id == user.id
                ? item.copyWith(subscribed: !user.subscribed)
                : item)
            .toList(growable: false);
        _pendingUserId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _pendingUserId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text('Find steak lovers', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Search and follow fellow carnivores.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _query,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by username or display name…',
            prefixIcon: Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
        ),
        if (_loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          AuthErrorBanner(message: _error!),
        ],
        if (!_loading &&
            _debouncedQuery.isNotEmpty &&
            _debouncedQuery.length < ApiConstraints.searchQueryMin) ...[
          const SizedBox(height: 16),
          Text(
            'Type at least ${ApiConstraints.searchQueryMin} characters to search.',
            style: TextStyle(color: palette.creamMuted),
          ),
        ],
        if (!_loading &&
            _debouncedQuery.length >= ApiConstraints.searchQueryMin &&
            _results.isEmpty &&
            _error == null) ...[
          const SizedBox(height: 24),
          EmptyState(
            message: 'No users found for "$_debouncedQuery".',
            icon: Icons.person_search_outlined,
          ),
        ],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._results.map(
            (user) => UserSearchCard(
              user: user,
              pending: _pendingUserId == user.id,
              onFollowToggle:
                  _canFollow ? () => _toggleFollow(user) : null,
            ),
          ),
        ],
        if (widget.auth.hasScope('subscriptions:read')) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go('/following'),
              child: const Text('View people you follow'),
            ),
          ),
        ],
      ],
    );
  }
}
