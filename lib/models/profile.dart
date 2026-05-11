enum UserRole {
  driver,
  parent,
  admin;

  static UserRole fromString(String s) {
    return UserRole.values.firstWhere(
      (e) => e.name == s,
      orElse: () => UserRole.parent,
    );
  }
}

class Profile {
  final String id;
  final String fullName;
  final UserRole role;
  final String? phone;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        role: UserRole.fromString(m['role'] as String? ?? 'parent'),
        phone: m['phone'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'].toString())?.toLocal()
            : null,
      );

  Map<String, dynamic> toInsert() => {
        'id': id,
        'full_name': fullName,
        'role': role.name,
        if (phone != null) 'phone': phone,
      };
}
