enum AttendanceStatus {
  boarded,
  dropped,
  absent;

  static AttendanceStatus fromString(String s) =>
      values.firstWhere((e) => e.name == s,
          orElse: () => AttendanceStatus.absent);

  String get tr {
    switch (this) {
      case AttendanceStatus.boarded:
        return 'Bindi';
      case AttendanceStatus.dropped:
        return 'İndi';
      case AttendanceStatus.absent:
        return 'Gelmedi';
    }
  }
}

class Attendance {
  final String id;
  final String tripId;
  final String studentId;
  final AttendanceStatus status;
  final DateTime? timestamp;

  Attendance({
    required this.id,
    required this.tripId,
    required this.studentId,
    required this.status,
    this.timestamp,
  });

  factory Attendance.fromMap(Map<String, dynamic> m) => Attendance(
        id: m['id'] as String,
        tripId: m['trip_id'] as String? ?? '',
        studentId: m['student_id'] as String? ?? '',
        status: AttendanceStatus.fromString(
            m['status'] as String? ?? 'absent'),
        timestamp: m['timestamp'] != null
            ? DateTime.tryParse(m['timestamp'].toString())?.toLocal()
            : null,
      );
}
