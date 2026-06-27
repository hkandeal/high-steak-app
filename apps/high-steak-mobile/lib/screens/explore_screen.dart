import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../models/place.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../widgets/empty_state.dart';
import '../widgets/star_rating.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.auth,
    required this.api,
    this.placeId,
  });

  final AuthController auth;
  final ApiService api;
  final String? placeId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  double? _lat;
  double? _lng;
  String? _geoError;
  String? _error;
  bool _loading = true;
  List<PlaceNearbySummary> _places = [];
  List<SteakPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadLocation();
    if (!mounted) return;
    if (_lat != null && _lng != null) {
      await _loadNearby();
    }
    if (widget.placeId != null) {
      await _loadPlacePosts(widget.placeId!);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _geoError = 'Allow location access to find steakhouses near you.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (_) {
      setState(() => _geoError = 'Could not determine your location.');
    }
  }

  Future<void> _loadNearby() async {
    try {
      final page = await widget.api.fetchNearbyPlaces(
        lat: _lat!,
        lng: _lng!,
        radiusM: 50000,
        size: 30,
      );
      setState(() => _places = page.content);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadPlacePosts(String placeId) async {
    try {
      final page = await widget.api.fetchPlacePosts(placeId);
      setState(() => _posts = page.content);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    PlaceNearbySummary? selectedPlace;
    if (widget.placeId != null) {
      for (final place in _places) {
        if (place.id == widget.placeId) {
          selectedPlace = place;
          break;
        }
      }
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.placeId != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (selectedPlace != null) ...[
            Text(selectedPlace.name, style: theme.textTheme.headlineSmall),
            if (selectedPlace.formattedAddress != null)
              Text(
                selectedPlace.formattedAddress!,
                style: TextStyle(color: palette.creamMuted),
              ),
            const SizedBox(height: 16),
          ],
          if (_error != null) Text(_error!, style: TextStyle(color: palette.errorText)),
          if (_posts.isEmpty)
            const EmptyState(
              message: 'No public posts at this place yet.',
            )
          else
            ..._posts.map((post) {
              final image = post.primaryImageUrl;
              return Card(
                child: ListTile(
                  leading: image == null
                      ? null
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            resolveApiImageUrl(image),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                  title: Text(post.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRating(value: post.rating, size: 18),
                      Text('by ${post.author.displayName}',
                          style: TextStyle(color: palette.creamMuted, fontSize: 12)),
                    ],
                  ),
                  onTap: () => context.push('/posts/${post.id}'),
                ),
              );
            }),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text('Explore nearby', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Steakhouses with recent ratings from the community.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (_geoError != null) Text(_geoError!, style: TextStyle(color: palette.errorText)),
        if (_error != null) Text(_error!, style: TextStyle(color: palette.errorText)),
        if (_places.isEmpty && _geoError == null && _error == null)
          const EmptyState(
            message: 'No tagged steakhouses nearby yet. Be the first to rate one.',
          ),
        ..._places.map(
          (place) => Card(
            child: ListTile(
              leading: place.coverImageUrl == null
                  ? null
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        resolveApiImageUrl(place.coverImageUrl!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
              title: Text(place.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (place.formattedAddress != null) place.formattedAddress!,
                      _formatDistance(place.distanceM),
                      '${place.postCount} posts',
                      if (place.avgRating != null) '${place.avgRating!.toStringAsFixed(1)} avg',
                    ].join(' · '),
                    style: TextStyle(color: palette.creamMuted, fontSize: 12),
                  ),
                  if (place.isGoogleCover)
                    Text(
                      'Photos © Google',
                      style: TextStyle(color: palette.creamMuted, fontSize: 10),
                    ),
                ],
              ),
              onTap: () => context.push('/explore/${place.id}'),
            ),
          ),
        ),
      ],
    );
  }
}
