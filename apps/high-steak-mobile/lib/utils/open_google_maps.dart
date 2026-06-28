import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart';
import 'google_maps.dart';

Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
  try {
    return await launchUrl(uri, mode: mode);
  } catch (error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('openGoogleMapsForPlace failed for $uri ($mode): $error');
    }
    return false;
  }
}

Future<bool> openGoogleMapsForPlace(PlaceSummary place) async {
  final lat = place.latitude.trim();
  final lng = place.longitude.trim();
  final hasCoordinates =
      lat.isNotEmpty && lng.isNotEmpty && lat != '0' && lng != '0';

  if (hasCoordinates) {
    final label = Uri.encodeComponent(place.name);
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    final httpsUri = Uri.parse(googleMapsUrlForPlace(place));

    if (Platform.isAndroid) {
      if (await _tryLaunch(geoUri, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }
      if (await _tryLaunch(httpsUri, LaunchMode.externalApplication)) {
        return true;
      }
      return _tryLaunch(httpsUri, LaunchMode.platformDefault);
    }

    if (await _tryLaunch(geoUri, LaunchMode.externalApplication)) {
      return true;
    }
    return _tryLaunch(httpsUri, LaunchMode.externalApplication);
  }

  final searchUri = Uri.parse(googleMapsUrlForPlace(place));
  if (await _tryLaunch(searchUri, LaunchMode.externalApplication)) {
    return true;
  }
  return _tryLaunch(searchUri, LaunchMode.platformDefault);
}
