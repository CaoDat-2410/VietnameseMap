class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.employeeId,
    this.studentId,
  });

  final int id;
  final String email;
  final String role;
  final String status;
  final int? employeeId;
  final int? studentId;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: json['id'] as int? ?? 0,
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        status: json['status'] as String? ?? '',
        employeeId: json['employeeId'] as int?,
        studentId: json['studentId'] as int?,
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
