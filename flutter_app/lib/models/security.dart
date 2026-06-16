class LoginHistoryItem {
  final int id;
  final String? userId;
  final String? email;
  final String? deviceName;
  final String? userAgent;
  final String? ipAddress;
  final bool success;
  final String? reason;
  final bool suspicious;
  final DateTime createdAt;

  LoginHistoryItem({
    required this.id,
    this.userId,
    this.email,
    this.deviceName,
    this.userAgent,
    this.ipAddress,
    required this.success,
    this.reason,
    required this.suspicious,
    required this.createdAt,
  });

  factory LoginHistoryItem.fromJson(Map<String, dynamic> json) {
    return LoginHistoryItem(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      email: json['email'] as String?,
      deviceName: json['device_name'] as String?,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
      success: json['success'] == true,
      reason: json['reason'] as String?,
      suspicious: json['suspicious'] == true,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class SecurityAlert {
  final int id;
  final String? userId;
  final String type;
  final String message;
  final String severity;
  final bool read;
  final DateTime createdAt;

  SecurityAlert({
    required this.id,
    this.userId,
    required this.type,
    required this.message,
    required this.severity,
    required this.read,
    required this.createdAt,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      type: json['type'] as String? ?? 'ALERT',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'MEDIUM',
      read: json['read'] == true,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class SecurityIssue {
  final String title;
  final String description;
  final String severity;

  SecurityIssue({
    required this.title,
    required this.description,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'severity': severity,
    };
  }
}

class SecurityDashboard {
  final int securityScore;
  final bool twoFactorEnabled;
  final bool emailVerified;
  final bool phoneVerified;
  final bool hasEmail;
  final bool hasPhoneNumber;
  final DateTime? lastLoginAt;

  SecurityDashboard({
    required this.securityScore,
    required this.twoFactorEnabled,
    required this.emailVerified,
    required this.phoneVerified,
    required this.hasEmail,
    required this.hasPhoneNumber,
    this.lastLoginAt,
  });
}
