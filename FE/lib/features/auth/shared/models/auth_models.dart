class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.employeeId,
    this.studentId,
    this.avatarObjectKey,
    this.fullName,
    this.phone,
    this.firebaseUser = false,
  });

  final int id;
  final String email;
  final String role;
  final String status;
  final int? employeeId;
  final int? studentId;
  final String? avatarObjectKey;
  final String? fullName;
  final String? phone;
  final bool firebaseUser;

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!.trim();
    return email.split('@').first;
  }

  String get initials {
    final name = displayName;
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  bool get hasPassword => !firebaseUser;

  /// True for student accounts that can edit their phone.
  bool get canEditPhone => role == 'STUDENT';

  AuthUserModel copyWith({
    String? email,
    String? status,
    String? avatarObjectKey,
    String? fullName,
    String? phone,
  }) {
    return AuthUserModel(
      id: id,
      email: email ?? this.email,
      role: role,
      status: status ?? this.status,
      employeeId: employeeId,
      studentId: studentId,
      avatarObjectKey: avatarObjectKey ?? this.avatarObjectKey,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      firebaseUser: firebaseUser,
    );
  }

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: json['id'] as int? ?? 0,
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        status: json['status'] as String? ?? '',
        employeeId: json['employeeId'] as int?,
        studentId: json['studentId'] as int?,
        avatarObjectKey: json['avatarObjectKey'] as String?,
        fullName: json['fullName'] as String?,
        phone: json['phone'] as String?,
        firebaseUser: json['firebaseUser'] as bool? ?? false,
      );
}

class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final AuthUserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        expiresIn: json['expiresIn'] as int? ?? 0,
        user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}