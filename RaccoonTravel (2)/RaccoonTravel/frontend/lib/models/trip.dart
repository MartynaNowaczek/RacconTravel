class Trip {
  final int id;

  final String tripName;

  final String originName;
  final String? originPlaceId;

  final String destinationName;
  final String? destinationPlaceId;

  final DateTime startDate;
  final DateTime endDate;

  final String? photoUrl;
  final String status;

  Trip({
    required this.id,
    required this.tripName,
    required this.originName,
    required this.originPlaceId,
    required this.destinationName,
    required this.destinationPlaceId,
    required this.startDate,
    required this.endDate,
    required this.photoUrl,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      tripName: json['trip_name'] as String,
      originName: json['origin_name'] as String,
      originPlaceId: json['origin_place_id'] as String?,
      destinationName: json['destination_name'] as String,
      destinationPlaceId: json['destination_place_id'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
    );
  }
}