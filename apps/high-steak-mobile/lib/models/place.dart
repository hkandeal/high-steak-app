class PlaceSummary {
  const PlaceSummary({
    required this.id,
    required this.provider,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.locationPrecision,
    this.previewPhotoUrl,
    this.previewPhotoSource,
  });

  final String id;
  final String provider;
  final String name;
  final String? formattedAddress;
  final String latitude;
  final String longitude;
  final String locationPrecision;
  final String? previewPhotoUrl;
  final String? previewPhotoSource;

  bool get isGooglePreview => previewPhotoSource == 'GOOGLE';

  factory PlaceSummary.fromJson(Map<String, dynamic> json) {
    return PlaceSummary(
      id: json['id'] as String,
      provider: json['provider'] as String? ?? 'manual',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formattedAddress'] as String?,
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
      locationPrecision: json['locationPrecision'] as String? ?? 'EXACT',
      previewPhotoUrl: json['previewPhotoUrl'] as String?,
      previewPhotoSource: json['previewPhotoSource'] as String?,
    );
  }
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.provider,
    required this.providerPlaceId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.previewPhotoUrl,
  });

  final String provider;
  final String providerPlaceId;
  final String name;
  final String? formattedAddress;
  final String? latitude;
  final String? longitude;
  final String? previewPhotoUrl;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      provider: json['provider'] as String? ?? 'google',
      providerPlaceId: json['providerPlaceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formattedAddress'] as String?,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      previewPhotoUrl: json['previewPhotoUrl'] as String?,
    );
  }
}

class PlaceNearbySummary {
  const PlaceNearbySummary({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.distanceM,
    required this.postCount,
    required this.avgRating,
    required this.coverImageUrl,
    this.coverImageSource,
  });

  final String id;
  final String name;
  final String? formattedAddress;
  final String latitude;
  final String longitude;
  final int distanceM;
  final int postCount;
  final double? avgRating;
  final String? coverImageUrl;
  final String? coverImageSource;

  factory PlaceNearbySummary.fromJson(Map<String, dynamic> json) {
    return PlaceNearbySummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      formattedAddress: json['formattedAddress'] as String?,
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
      distanceM: json['distanceM'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      coverImageUrl: json['coverImageUrl'] as String?,
      coverImageSource: json['coverImageSource'] as String?,
    );
  }

  bool get isGoogleCover => coverImageSource == 'GOOGLE';
}
