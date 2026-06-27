import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../models/page_response.dart';
import '../models/place.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
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
    required this.api,
    this.placeId,
  });

  final ApiService api;
  final String? placeId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  _ExploreMode _mode = _ExploreMode.browse;
  MapLatLng? _userCoords;
  MapLatLng? _savedCenter;
  MapLatLng _mapFocus = ExploreLocationStore.exploreDefaultCenter;
  bool _flyMap = false;
  bool _geoLoading = false;
  bool _locationRequested = false;
  String? _geoError;

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

  bool get _usingFallbackArea => _userCoords == null && _savedCenter != null;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final saved = await ExploreLocationStore.readBrowseCenter();
    final cached = await ExploreLocationStore.readCoords();
    if (!mounted) return;
    setState(() {
      _savedCenter = saved;
      _userCoords = cached;
      _mapFocus = saved ?? cached ?? ExploreLocationStore.exploreDefaultCenter;
    });
    if (widget.placeId != null) {
      await _loadPlaceDetail(widget.placeId!);
      return;
    }
    unawaited(_requestLocation());
    if (_browseCenter != null) {
      await _loadNearbyPins();
    }
  }

  Future<void> _requestLocation() async {
    if (_geoLoading) return;
    setState(() {
      _locationRequested = true;
      _geoLoading = true;
      _geoError = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _geoError =
              'Location is blocked. Search for a restaurant above, or enable location in settings.';
        });
        return;
      }

      Position? position;
      for (final settings in [
        const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 12)),
        const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
      ]) {
        try {
          position = await Geolocator.getCurrentPosition(locationSettings: settings);
          break;
        } catch (_) {
          continue;
        }
      }

      if (position == null) {
        if (!mounted) return;
        if (_userCoords == null && _savedCenter == null) {
          setState(() {
            _geoError =
                'Could not detect your location. Search for a restaurant above, or tap ◎ on the map.';
          });
        }
        return;
      }

      final coords = MapLatLng(lat: position.latitude, lng: position.longitude);
      await ExploreLocationStore.persistCoords(coords);
      await ExploreLocationStore.persistBrowseCenter(coords);
      if (!mounted) return;
      setState(() {
        _userCoords = coords;
        _savedCenter = coords;
        if (_mode == _ExploreMode.browse) {
          _mapFocus = coords;
          _flyMap = true;
        }
        _geoError = null;
      });
      if (_mode == _ExploreMode.browse) {
        await _loadNearbyPins();
      }
    } finally {
      if (mounted) setState(() => _geoLoading = false);
    }
  }

  Future<void> _loadNearbyPins() async {
    final center = _browseCenter;
    if (center == null || _mode != _ExploreMode.browse) return;
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSearchPlace(PlaceSummary? place) async {
    setState(() => _searchPlace = place);
    if (place == null) {
      setState(() {
        _searchedPin = null;
        _mode = _ExploreMode.browse;
      });
      await _loadNearbyPins();
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

  Future<void> _handleLocateMe() async {
    setState(() {
      _searchPlace = null;
      _searchedPin = null;
      _mode = _ExploreMode.browse;
      _flyMap = true;
      if (_userCoords != null) {
        _mapFocus = _userCoords!;
      }
    });
    await _requestLocation();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    if (widget.placeId != null) {
      return _buildPlaceDetail(context, palette, theme);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text('Explore', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          _mode == _ExploreMode.search
              ? 'Showing your searched restaurant. Clear search to see all nearby reviews.'
              : 'Pins are steakhouses with community reviews near you.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        PlacePicker(
          api: widget.api,
          value: _searchPlace,
          onChanged: (place) => unawaited(_handleSearchPlace(place)),
          hideLabel: true,
          placeholder: 'Search restaurants on the map…',
          hideFooterHint: true,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.52,
          child: ExploreMap(
            center: _mapFocus,
            userCoords: _userCoords,
            places: _mapPlaces,
            selectedPlaceId: _searchedPin?.id,
            onLocateMe: () => unawaited(_handleLocateMe()),
            locating: _geoLoading,
            flyToCenter: _flyMap,
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          Text('Loading map…', style: TextStyle(color: palette.creamMuted)),
        if (_browseCenter == null && !_locationRequested)
          Text(
            'Finding your location to show nearby steakhouses…',
            style: TextStyle(color: palette.creamMuted),
          ),
        if (_usingFallbackArea && _geoError != null)
          Text(
            'Live GPS unavailable — showing reviews near your last searched area. Tap ◎ to retry location.',
            style: TextStyle(color: palette.creamMuted, fontSize: 13),
          ),
        if (_locationRequested && _geoError != null && _browseCenter == null)
          Text(_geoError!, style: TextStyle(color: palette.errorText)),
        if (_error != null) Text(_error!, style: TextStyle(color: palette.errorText)),
        if (!_loading &&
            _mode == _ExploreMode.browse &&
            _browseCenter != null &&
            _nearbyPlaces.isEmpty &&
            _error == null)
          Text(
            'No tagged steakhouses in this area yet. Search for a restaurant or rate a steak to add the first pin.',
            style: TextStyle(color: palette.creamMuted),
          ),
      ],
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
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ExploreMap(
              center: MapLatLng(
                lat: double.parse(_selectedPlace!.latitude),
                lng: double.parse(_selectedPlace!.longitude),
              ),
              userCoords: _userCoords,
              places: [_selectedPlace!],
              selectedPlaceId: widget.placeId,
              onLocateMe: () => unawaited(_handleLocateMe()),
              locating: _geoLoading,
              flyToCenter: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_posts.isEmpty && !_loading)
          const EmptyState(message: 'No public posts at this place yet.')
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
