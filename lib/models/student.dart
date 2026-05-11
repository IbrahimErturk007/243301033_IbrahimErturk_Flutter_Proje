class Student {
  final String id;
  final String fullName;
  final String parentId;
  final String? routeId;
  final String? schoolNo;
  final DateTime? createdAt;

  Student({
    required this.id,
    required this.fullName,
    required this.parentId,
    this.routeId,
    this.schoolNo,
    this.createdAt,
  });

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        parentId: m['parent_id'] as String? ?? '',
        routeId: m['route_id'] as String?,
        schoolNo: m['school_no'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'].toString())?.toLocal()
            : null,
      );

  Map<String, dynamic> toInsert() => {
        'full_name': fullName,
        'parent_id': parentId,
        if (routeId != null) 'route_id': routeId,
        if (schoolNo != null) 'school_no': schoolNo,
      };
}
