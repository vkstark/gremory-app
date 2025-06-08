class User {
  final int id;
  final String? username;
  final String? email;
  final String displayName;
  final String userType;
  final String status;
  final String? phoneNumber;
  final String? timezone;
  final String languagePreference;
  final String? guestSessionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    this.username,
    this.email,
    required this.displayName,
    required this.userType,
    required this.status,
    this.phoneNumber,
    this.timezone,
    required this.languagePreference,
    this.guestSessionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String?,
      email: json['email'] as String?,
      displayName: json['display_name'] as String? ?? 'User',
      userType: json['user_type'] as String? ?? 'guest',
      status: json['status'] as String? ?? 'active',
      phoneNumber: json['phone_number'] as String?,
      timezone: json['timezone'] as String?,
      languagePreference: json['language_preference'] as String? ?? 'en',
      guestSessionId: json['guest_session_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'user_type': userType,
      'status': status,
      'phone_number': phoneNumber,
      'timezone': timezone,
      'language_preference': languagePreference,
      'guest_session_id': guestSessionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get isGuest => userType == 'guest';
  bool get isRegistered => userType == 'registered';
  bool get isBot => userType == 'bot';
  bool get isActive => status == 'active';
  bool get isDeleted => status == 'deleted';

  String get displayIdentifier {
    if (username != null && username!.isNotEmpty) return username!;
    if (email != null && email!.isNotEmpty) return email!;
    return displayName;
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? displayName,
    String? userType,
    String? status,
    String? phoneNumber,
    String? timezone,
    String? languagePreference,
    String? guestSessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      timezone: timezone ?? this.timezone,
      languagePreference: languagePreference ?? this.languagePreference,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
