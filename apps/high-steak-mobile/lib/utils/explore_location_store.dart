import 'package:latlong2/latlong.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MapLatLng {
  const MapLatLng({required this.lat, required this.lng});

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  static MapLatLng? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final lat = parsed['lat'];
      final lng = parsed['lng'];
      if (lat is num && lng is num) {
        return MapLatLng(lat: lat.toDouble(), lng: lng.toDouble());
      }
    } catch (_) {
      // ignore corrupt cache
    }
    return null;
  }

  LatLng get asLatLng => LatLng(lat, lng);
}

class ExploreLocationStore {
  static const exploreDefaultCenter = MapLatLng(lat: 25.2048, lng: 55.2708);
  static const _coordsKey = 'highsteak:explore:lastCoords';
  static const _browseCenterKey = 'highsteak:explore:browseCenter';

  static Future<MapLatLng?> readCoords() async {
    final prefs = await SharedPreferences.getInstance();
    return MapLatLng.fromJsonString(prefs.getString(_coordsKey));
  }

  static Future<MapLatLng?> readBrowseCenter() async {
    final prefs = await SharedPreferences.getInstance();
    return MapLatLng.fromJsonString(prefs.getString(_browseCenterKey));
  }

  static Future<void> persistCoords(MapLatLng coords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coordsKey, jsonEncode(coords.toJson()));
  }

  static Future<void> persistBrowseCenter(MapLatLng center) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_browseCenterKey, jsonEncode(center.toJson()));
  }
}
