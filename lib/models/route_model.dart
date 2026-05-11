class RouteModel {
  final String id;
  final String routeName;
  final String? driverId;
  final DateTime? createdAt;

  RouteModel({
    required this.id,
    required this.routeName,
    this.driverId,
    this.createdAt,
  });

  factory RouteModel.fromMap(Map<String, dynamic> m) => RouteModel(
        id: m['id'] as String,
        routeName: m['route_name'] as String? ?? '',
        driverId: m['driver_id'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'].toString())?.toLocal()
            : null,
      );
}
