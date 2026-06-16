class User {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final bool emailVerified;
  final bool phoneVerified;
  final bool twoFactorEnabled;
  final String role;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.emailVerified,
    required this.phoneVerified,
    required this.twoFactorEnabled,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Khách',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
      twoFactorEnabled: json['twoFactorEnabled'] == true,
      role: json['role'] as String? ?? 'USER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'role': role,
    };
  }
}