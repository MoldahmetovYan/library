class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      email: _stringValue(json['email']) ?? _stringValue(json['username']) ?? '',
      fullName:
          _stringValue(json['fullName']) ?? _stringValue(json['name']) ?? '',
      role: _stringValue(json['role']) ?? _stringValue(json['type']) ?? 'user',
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? _stringValue(dynamic value) {
  return value?.toString();
}
