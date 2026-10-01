class PlaceSuggestion {
  final String placeId;
  final String name;
  final double lat;
  final double lon;
  final String? country;
  final String? city;

  PlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lon,
    required this.country,
    required this.city,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'],
      name: json['name'],
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      country: json['country'],
      city: json['city'],
    );
  }
}