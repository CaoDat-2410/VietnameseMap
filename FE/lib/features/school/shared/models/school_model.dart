class PagedResponse<T> {
  const PagedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return PagedResponse<T>(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => fromJsonT(e))
          .toList(),
      page: json['page'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class SchoolModel {
  const SchoolModel({
    required this.schoolUid,
    required this.provinceCode,
    required this.provinceName,
    required this.communeCode,
    required this.communeName,
    required this.schoolCode,
    required this.schoolName,
    required this.address,
    required this.areaType,
  });

  final String schoolUid;
  final String provinceCode;
  final String provinceName;
  final String communeCode;
  final String communeName;
  final String schoolCode;
  final String schoolName;
  final String address;
  final String areaType;

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      schoolUid: json['schoolUid'] as String? ?? '',
      provinceCode: json['provinceCode'] as String? ?? '',
      provinceName: json['provinceName'] as String? ?? '',
      communeCode: json['communeCode'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      areaType: json['areaType'] as String? ?? '',
    );
  }
}

class StudentModel {
  const StudentModel({
    required this.id,
    required this.schoolUid,
    required this.fullName,
    required this.grade,
    required this.className,
  });

  final int id;
  final String schoolUid;
  final String fullName;
  final String grade;
  final String className;

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'] as int? ?? 0,
        schoolUid: json['schoolUid'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        className: json['className'] as String? ?? '',
      );
}

class PersonModel {
  const PersonModel({
    required this.id,
    required this.schoolUid,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String schoolUid;
  final String fullName;
  final String role;

  factory PersonModel.fromJson(Map<String, dynamic> json) => PersonModel(
        id: json['id'] as int? ?? 0,
        schoolUid: json['schoolUid'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );
}

class StudentRelativeModel {
  const StudentRelativeModel({
    required this.id,
    required this.schoolUid,
    required this.fullName,
    required this.studentId,
    required this.relationship,
    required this.phone,
  });

  final int id;
  final String schoolUid;
  final String fullName;
  final int studentId;
  final String relationship;
  final String phone;

  factory StudentRelativeModel.fromJson(Map<String, dynamic> json) =>
      StudentRelativeModel(
        id: json['id'] as int? ?? 0,
        schoolUid: json['schoolUid'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        studentId: json['studentId'] as int? ?? 0,
        relationship: json['relationship'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}

class SchoolDetailModel {
  const SchoolDetailModel({
    required this.school,
    required this.students,
    required this.persons,
    required this.relatives,
  });

  final SchoolModel school;
  final List<StudentModel> students;
  final List<PersonModel> persons;
  final List<StudentRelativeModel> relatives;

  factory SchoolDetailModel.fromJson(Map<String, dynamic> json) {
    return SchoolDetailModel(
      school: SchoolModel.fromJson(json['school'] as Map<String, dynamic>),
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      persons: (json['persons'] as List<dynamic>? ?? [])
          .map((e) => PersonModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatives: (json['relatives'] as List<dynamic>? ?? [])
          .map((e) => StudentRelativeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
