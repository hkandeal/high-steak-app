import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'explore_location_store.dart';

class UserCoords {
  const UserCoords({required this.lat, required this.lng, this.fromCache = false});

  final double lat;
  final double lng;
  final bool fromCache;

  MapLatLng get asMapLatLng => MapLatLng(lat: lat, lng: lng);
}

class LocationRequestResult {
  const LocationRequestResult({
    this.coords,
    this.error,
    this.permissionDeniedForever = false,
    this.serviceDisabled = false,
  });

  final UserCoords? coords;
  final String? error;
  final bool permissionDeniedForever;
  final bool serviceDisabled;
}

LocationSettings _locationSettings({
  required LocationAccuracy accuracy,
  bool forceAndroidLocationManager = false,
}) {
  if (!kIsWeb && Platform.isAndroid) {
    return AndroidSettings(
      accuracy: accuracy,
      forceLocationManager: forceAndroidLocationManager,
      intervalDuration: const Duration(seconds: 5),
    );
  }
  if (!kIsWeb && Platform.isIOS) {
    return AppleSettings(
      accuracy: accuracy,
      activityType: ActivityType.other,
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: false,
    );
  }
  return LocationSettings(accuracy: accuracy);
}

Future<Position?> _readCurrentPosition(LocationSettings settings) async {
  try {
    return await Geolocator.getCurrentPosition(locationSettings: settings)
        .timeout(const Duration(seconds: 45));
  } on TimeoutException {
    return null;
  } catch (_) {
    return null;
  }
}

Future<LocationPermission> _ensurePermission() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    permission = await Geolocator.requestPermission();
  }
  return permission;
}

Future<LocationRequestResult> requestUserLocation() async {
  final savedCoords = await ExploreLocationStore.readCoords();
  final savedBrowse = await ExploreLocationStore.readBrowseCenter();

  UserCoords? coordsFrom(MapLatLng? point, {bool fromCache = true}) {
    if (point == null) return null;
    return UserCoords(lat: point.lat, lng: point.lng, fromCache: fromCache);
  }

  if (!await Geolocator.isLocationServiceEnabled()) {
    return LocationRequestResult(
      coords: coordsFrom(savedBrowse) ?? coordsFrom(savedCoords),
      serviceDisabled: true,
      error: 'Location services are off. Turn them on in Settings, or search for a restaurant below.',
    );
  }

  final permission = await _ensurePermission();

  if (permission == LocationPermission.deniedForever) {
    return LocationRequestResult(
      coords: coordsFrom(savedBrowse) ?? coordsFrom(savedCoords),
      permissionDeniedForever: true,
      error: 'Location access is blocked. Tap below to open Settings and allow location for High Steaks.',
    );
  }

  if (permission == LocationPermission.denied) {
    return LocationRequestResult(
      coords: coordsFrom(savedBrowse) ?? coordsFrom(savedCoords),
      error: 'Location permission denied. Tap ◎ on the map to allow access, or search for a restaurant below.',
    );
  }

  Position? lastKnown;
  try {
    lastKnown = await Geolocator.getLastKnownPosition();
  } catch (_) {
    lastKnown = null;
  }

  final attempts = <LocationSettings>[
    _locationSettings(accuracy: LocationAccuracy.medium),
    _locationSettings(accuracy: LocationAccuracy.low),
    _locationSettings(accuracy: LocationAccuracy.high),
    if (!kIsWeb && Platform.isAndroid)
      _locationSettings(accuracy: LocationAccuracy.high, forceAndroidLocationManager: true),
  ];

  for (final settings in attempts) {
    final position = await _readCurrentPosition(settings);
    if (position == null) continue;

    final coords = MapLatLng(lat: position.latitude, lng: position.longitude);
    await ExploreLocationStore.persistCoords(coords);
    return LocationRequestResult(coords: UserCoords(lat: coords.lat, lng: coords.lng));
  }

  if (lastKnown != null) {
    final coords = MapLatLng(lat: lastKnown.latitude, lng: lastKnown.longitude);
    await ExploreLocationStore.persistCoords(coords);
    return LocationRequestResult(
      coords: UserCoords(lat: coords.lat, lng: coords.lng, fromCache: true),
    );
  }

  final fallback = coordsFrom(savedBrowse) ?? coordsFrom(savedCoords);
  if (fallback != null) {
    return LocationRequestResult(
      coords: fallback,
      error: 'Live GPS unavailable — showing your last known area. Search below to pick a different area.',
    );
  }

  return const LocationRequestResult(
    error: 'Could not detect your location. Tap ◎ on the map to try again, or search for a restaurant above.',
  );
}

Future<void> openLocationPermissionSettings({bool permissionBlocked = false}) async {
  if (permissionBlocked) {
    await Geolocator.openAppSettings();
    return;
  }
  await Geolocator.openLocationSettings();
}
