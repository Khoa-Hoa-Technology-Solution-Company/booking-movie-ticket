enum UserRole { user, admin }

class User {
  final String id; // UUID
  final String name;
  final String? email;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final UserRole role;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    this.email,
    required this.emailVerified,
    required this.twoFactorEnabled,
    required this.role,
    required this.failedLoginAttempts,
    this.lockedUntil,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Chưa đặt tên',
      email: json['email'] as String?,
      emailVerified: json['email_verified'] == true,
      twoFactorEnabled: json['two_factor_enabled'] == true,
      role: json['role'] == 'ADMIN' ? UserRole.admin : UserRole.user,
      failedLoginAttempts: json['failed_login_attempts'] as int? ?? 0,
      lockedUntil: json['locked_until'] != null ? DateTime.parse(json['locked_until'] as String) : null,
      lastLoginAt: json['last_login_at'] != null ? DateTime.parse(json['last_login_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified': emailVerified,
      'two_factor_enabled': twoFactorEnabled,
      'role': role == UserRole.admin ? 'ADMIN' : 'USER',
      'failed_login_attempts': failedLoginAttempts,
      'locked_until': lockedUntil?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}