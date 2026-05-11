enum TripType {
  morning,
  evening;

  static TripType fromString(String s) =>
      values.firstWhere((e) => e.name == s, orElse: () => TripType.morning);

  String get tr => this == TripType.morning ? 'Sabah' : 'Akşam';
}

enum TripStatus {
  active,
  completed;

  static TripStatus fromString(String s) =>
      values.firstWhere((e) => e.name == s, orElse: () => TripStatus.active);
}

class Trip {
  final String id;
  final String? routeId;
  final String driverId;
  final TripType tripType;
  final TripStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  Trip({
    required this.id,
    required this.driverId,
    required this.tripType,
    required this.status,
    this.routeId,
    this.startedAt,
    this.endedAt,
  });

  factory Trip.fromMap(Map<String, dynamic> m) => Trip(
        id: m['id'] as String,
        routeId: m['route_id'] as String?,
        driverId: m['driver_id'] as String? ?? '',
        tripType: TripType.fromString(m['trip_type'] as String? ?? 'morning'),
        status: TripStatus.fromString(m['status'] as String? ?? 'active'),
        startedAt: m['started_at'] != null
            ? DateTime.tryParse(m['started_at'].toString())?.toLocal()
            : null,
        endedAt: m['ended_at'] != null
            ? DateTime.tryParse(m['ended_at'].toString())?.toLocal()
            : null,
      );
}
