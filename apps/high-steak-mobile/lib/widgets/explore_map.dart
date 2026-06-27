import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../utils/explore_location_store.dart';
import 'star_rating.dart';

/// Must match the app bundle id — OSM blocks generic/unknown user agents.
const _mapUserAgentPackage = 'com.highsteak.highSteakMobile';

class ExploreMap extends StatefulWidget {
  const ExploreMap({
    super.key,
    required this.center,
    required this.userCoords,
    required this.places,
    required this.onLocateMe,
    required this.locating,
    this.selectedPlaceId,
    this.flyToCenter = true,
    this.flyKey = 0,
  });

  final MapLatLng center;
  final MapLatLng? userCoords;
  final List<PlaceNearbySummary> places;
  final String? selectedPlaceId;
  final VoidCallback onLocateMe;
  final bool locating;
  final bool flyToCenter;
  final int flyKey;

  @override
  State<ExploreMap> createState() => _ExploreMapState();
}

class _ExploreMapState extends State<ExploreMap> {
  final _mapController = MapController();
  String? _lastFlyKey;
  bool _mapReady = false;

  @override
  void didUpdateWidget(covariant ExploreMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.flyToCenter) return;
    if (widget.flyKey != oldWidget.flyKey) {
      _lastFlyKey = null;
    }
    if (widget.flyKey != oldWidget.flyKey ||
        oldWidget.center.lat != widget.center.lat ||
        oldWidget.center.lng != widget.center.lng) {
      _flyTo(widget.center);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    if (widget.flyToCenter) {
      _flyTo(widget.center);
    }
  }

  void _flyTo(MapLatLng center) {
    if (!_mapReady) return;
    final key = '${center.lat},${center.lng}';
    if (_lastFlyKey == key) return;
    _lastFlyKey = key;
    try {
      _mapController.move(LatLng(center.lat, center.lng), 13);
    } catch (_) {
      // Map controller not ready yet.
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
        color: const Color(0xFFDDDDDD),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.center.lat, widget.center.lng),
                initialZoom: 13,
                backgroundColor: const Color(0xFFDDDDDD),
                onMapReady: _onMapReady,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: _mapUserAgentPackage,
                ),
                if (widget.userCoords != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.userCoords!.lat, widget.userCoords!.lng),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: widget.places
                      .map((place) => _placeMarker(context, place))
                      .toList(growable: false),
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: palette.cardBg,
                elevation: 3,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: widget.locating ? null : widget.onLocateMe,
                  tooltip: 'Center on my location',
                  icon: widget.locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('◎', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _placeMarker(BuildContext context, PlaceNearbySummary place) {
    final palette = context.palette;
    final lat = double.tryParse(place.latitude);
    final lng = double.tryParse(place.longitude);
    if (lat == null || lng == null) {
      return Marker(point: const LatLng(0, 0), width: 0, height: 0, child: const SizedBox.shrink());
    }

    final hasReviews = place.postCount > 0;
    final label = hasReviews
        ? (place.avgRating != null ? place.avgRating!.toStringAsFixed(1) : '★')
        : '◆';

    return Marker(
      point: LatLng(lat, lng),
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _showPlaceSheet(context, place),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasReviews ? palette.gold : const Color(0xFF64748B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: hasReviews ? const Color(0xFF1A0A08) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: hasReviews ? 11 : 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaceSheet(BuildContext context, PlaceNearbySummary place) {
    final palette = context.palette;
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (place.coverImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    resolveApiImageUrl(place.coverImageUrl!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (place.isGoogleCover)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Photos © Google', style: TextStyle(color: palette.creamMuted, fontSize: 11)),
                ),
              const SizedBox(height: 8),
              Text(place.name, style: theme.textTheme.titleMedium),
              if (place.formattedAddress != null)
                Text(place.formattedAddress!, style: TextStyle(color: palette.creamMuted, fontSize: 13)),
              const SizedBox(height: 8),
              if (place.postCount > 0) ...[
                Row(
                  children: [
                    if (place.avgRating != null)
                      StarRating(value: place.avgRating!.round(), size: 18),
                    const SizedBox(width: 8),
                    Text('${place.postCount} review${place.postCount == 1 ? '' : 's'}'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/explore/${place.id}');
                    },
                    child: const Text('View posts'),
                  ),
                ),
              ] else ...[
                Text(
                  'No community reviews yet',
                  style: TextStyle(color: palette.creamMuted, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/post/new');
                    },
                    child: const Text('Be the first to rate'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
