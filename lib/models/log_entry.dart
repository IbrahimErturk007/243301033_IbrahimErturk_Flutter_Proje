class LogEntry {
  final String id;
  final String? userId;
  final String action;
  final String? details;
  final DateTime? createdAt;

  LogEntry({
    required this.id,
    required this.action,
    this.userId,
    this.details,
    this.createdAt,
  });

  factory LogEntry.fromMap(Map<String, dynamic> m) => LogEntry(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        action: m['action'] as String? ?? '',
        details: m['details'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'].toString())?.toLocal()
            : null,
      );
}
