import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../models/page_response.dart';
import '../models/place.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../utils/explore_location_service.dart';
import '../utils/explore_location_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/explore_map.dart';
import '../widgets/place_picker.dart';
import '../widgets/star_rating.dart';

enum _ExploreMode { browse, search }

PlaceNearbySummary _placeFromSummary(PlaceSummary place, {int postCount = 0}) {
  return PlaceNearbySummary(
    id: place.id,
    name: place.name,
    formattedAddress: place.formattedAddress,
    latitude: place.latitude,
    longitude: place.longitude,
    distanceM: 0,
    postCount: postCount,
    avgRating: null,
    coverImageUrl: place.previewPhotoUrl,
    coverImageSource: place.previewPhotoSource,
  );
}

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
  _ExploreMode _mode = _ExploreMode.browse;
  bool _flyMap = false;
  int _flyKey = 0;
  bool _geoLoading = false;
  bool _locationRequested = false;
  String? _geoError;

  MapLatLng? _userCoords;
  MapLatLng? _savedCenter;
  MapLatLng _mapFocus = ExploreLocationStore.exploreDefaultCenter;

  PlaceSummary? _searchPlace;
  PlaceNearbySummary? _searchedPin;
  List<PlaceNearbySummary> _nearbyPlaces = [];
  PlaceNearbySummary? _selectedPlace;
  List<SteakPost> _posts = [];

  bool _loading = false;
  String? _error;

  MapLatLng? get _browseCenter => _savedCenter ?? _userCoords;

  List<PlaceNearbySummary> get _mapPlaces {
    if (_mode == _ExploreMode.search && _searchedPin != null) {
      return [_searchedPin!];
    }
    return _nearbyPlaces;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (widget.placeId != null) {
      final saved = await ExploreLocationStore.readBrowseCenter();
      if (!mounted) return;
      if (saved != null) {
        setState(() => _mapFocus = saved);
      }
      await _loadPlaceDetail(widget.placeId!);
      return;
    }

    await _requestLocationAndLoad();
  }

  Future<void> _requestLocationAndLoad() async {
    setState(() {
      _locationRequested = true;
      _geoLoading = true;
      _geoError = null;
      _mode = _ExploreMode.browse;
    });

    final result = await requestUserLocation();
    if (!mounted) return;

    MapLatLng? center;
    if (result.coords != null) {
      center = result.coords!.asMapLatLng;
      await ExploreLocationStore.persistBrowseCenter(center);
    } else {
      final saved = await ExploreLocationStore.readBrowseCenter();
      center = saved;
    }

    setState(() {
      _geoLoading = false;
      _geoError = result.error;
      if (result.coords != null) {
        _userCoords = center;
        _savedCenter = center;
      } else if (center != null) {
        _savedCenter = center;
      }
      if (center != null) {
        _mapFocus = center;
        _flyKey++;
        _flyMap = true;
      }
    });

    if (center != null && _mode == _ExploreMode.browse) {
      await _loadNearbyPins(center);
    }
  }

  Future<void> _loadNearbyPins(MapLatLng center) async {
    if (_mode != _ExploreMode.browse) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await widget.api.fetchNearbyPlaces(
        lat: center.lat,
        lng: center.lng,
        radiusM: 50000,
        size: 50,
      );
      if (!mounted) return;
      setState(() => _nearbyPlaces = page.content);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = [];
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPlaceDetail(String placeId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.fetchPlace(placeId),
        widget.api.fetchPlacePosts(placeId),
      ]);
      final place = results[0] as PlaceSummary;
      final postsPage = results[1] as PageResponse<SteakPost>;
      if (!mounted) return;
      setState(() {
        _selectedPlace = _placeFromSummary(place, postCount: postsPage.totalElements);
        _posts = postsPage.content;
        _mapFocus = MapLatLng(
          lat: double.parse(place.latitude),
          lng: double.parse(place.longitude),
        );
        _flyKey++;
        _flyMap = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLocateMe() async {
    setState(() {
      _searchPlace = null;
      _searchedPin = null;
    });
    await _requestLocationAndLoad();
  }

  Future<void> _handleSearchPlace(PlaceSummary? place) async {
    setState(() => _searchPlace = place);

    if (place == null) {
      setState(() {
        _searchedPin = null;
        _mode = _ExploreMode.browse;
      });
      final center = _browseCenter;
      if (center != null) {
        await _loadNearbyPins(center);
      }
      return;
    }

    final center = MapLatLng(
      lat: double.parse(place.latitude),
      lng: double.parse(place.longitude),
    );
    await ExploreLocationStore.persistBrowseCenter(center);

    setState(() {
      _mode = _ExploreMode.search;
      _savedCenter = center;
      _mapFocus = center;
      _flyKey++;
      _flyMap = true;
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.api.fetchNearbyPlaces(lat: center.lat, lng: center.lng, radiusM: 2000, size: 50),
        widget.api.fetchPlacePosts(place.id, size: 1),
      ]);
      final nearbyPage = results[0] as PageResponse<PlaceNearbySummary>;
      final postsPage = results[1] as PageResponse<SteakPost>;

      PlaceNearbySummary? communityMatch;
      for (final item in nearbyPage.content) {
        if (item.id == place.id) {
          communityMatch = item;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _searchedPin = communityMatch ?? _placeFromSummary(place, postCount: postsPage.totalElements);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchedPin = _placeFromSummary(place);
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    if (widget.placeId != null) {
      return _buildPlaceDetail(context, palette, theme);
    }

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Explore', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              _mode == _ExploreMode.search
                  ? 'Showing your searched restaurant. Clear search to see all nearby reviews.'
                  : 'Pins are steakhouses with community reviews near you.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            PlacePicker(
              api: widget.api,
              value: _searchPlace,
              onChanged: (place) => unawaited(_handleSearchPlace(place)),
              hideLabel: true,
              placeholder: 'Search restaurants on the map…',
              hideFooterHint: true,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ExploreMap(
                center: _mapFocus,
                userCoords: _userCoords,
                places: _mapPlaces,
                selectedPlaceId: _searchedPin?.id,
                onLocateMe: () => unawaited(_handleLocateMe()),
                locating: _geoLoading,
                flyToCenter: _flyMap,
                flyKey: _flyKey,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading || _geoLoading)
              Text('Loading map…', style: TextStyle(color: palette.creamMuted, fontSize: 13)),
            if (_browseCenter == null && !_locationRequested)
              Text('Finding your location…', style: TextStyle(color: palette.creamMuted, fontSize: 13)),
            if (_geoError != null && _browseCenter != null)
              Text(_geoError!, style: TextStyle(color: palette.creamMuted, fontSize: 13), textAlign: TextAlign.center),
            if (_geoError != null && _browseCenter == null)
              Text(_geoError!, style: TextStyle(color: palette.errorText, fontSize: 13), textAlign: TextAlign.center),
            if (_error != null) Text(_error!, style: TextStyle(color: palette.errorText, fontSize: 13)),
            if (!_loading &&
                _mode == _ExploreMode.browse &&
                _browseCenter != null &&
                _nearbyPlaces.isEmpty &&
                _error == null &&
                !_geoLoading)
              Text(
                'No tagged steakhouses in this area yet. Search for a restaurant or rate a steak to add the first pin.',
                style: TextStyle(color: palette.creamMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceDetail(BuildContext context, AppPalette palette, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        TextButton.icon(
          onPressed: () => context.go('/explore'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to map'),
        ),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (_error != null) Text(_error!, style: TextStyle(color: palette.errorText)),
        if (_selectedPlace != null) ...[
          Text(_selectedPlace!.name, style: theme.textTheme.headlineSmall),
          if (_selectedPlace!.formattedAddress != null)
            Text(_selectedPlace!.formattedAddress!, style: TextStyle(color: palette.creamMuted)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ExploreMap(
              center: _mapFocus,
              userCoords: _userCoords,
              places: [_selectedPlace!],
              selectedPlaceId: widget.placeId,
              onLocateMe: () => unawaited(_handleLocateMe()),
              locating: _geoLoading,
              flyToCenter: true,
              flyKey: _flyKey,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_posts.isEmpty && !_loading) ...[
          const EmptyState(message: 'No public posts at this place yet.'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/post/new?placeId=${widget.placeId}'),
              child: const Text('Rate your steak'),
            ),
          ),
        ] else
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
                    Text(
                      'by ${post.author.displayName}',
                      style: TextStyle(color: palette.creamMuted, fontSize: 12),
                    ),
                  ],
                ),
                onTap: () => context.push('/posts/${post.id}'),
              ),
            );
          }),
      ],
    );
  }
}
