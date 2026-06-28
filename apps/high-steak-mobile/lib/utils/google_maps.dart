import '../models/place.dart';

String googleMapsUrlForPlace(PlaceSummary place) {
  final lat = place.latitude.trim();
  final lng = place.longitude.trim();
  if (lat.isNotEmpty && lng.isNotEmpty && lat != '0' && lng != '0') {
    final query = Uri.encodeComponent('$lat,$lng');
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }
  final label = place.formattedAddress != null && place.formattedAddress!.isNotEmpty
      ? '${place.name}, ${place.formattedAddress}'
      : place.name;
  return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(label)}';
}
