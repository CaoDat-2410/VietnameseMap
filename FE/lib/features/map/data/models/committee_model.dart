class CommitteeModel {
  const CommitteeModel({
    required this.code,
    required this.name,
    required this.type,
    required this.parentCode,
    this.address,
    this.phone,
    this.centroidLat,
    this.centroidLng,
  });

  final String code;
  final String name;
  final String type;  // intentionally non-nullable — '' is valid stand-in for missing loại UBND
  final String parentCode;  // FK to province.code
  final String? address;
  final String? phone;
  final double? centroidLat;  // from centroid_lat
  final double? centroidLng;  // from centroid_lon

  factory CommitteeModel.fromJson(Map<String, dynamic> json) {
    return CommitteeModel(
      code: json['code'] as String,
      name: json['name'] as String,
      type: (json['type'] ?? '') as String,
      parentCode: json['parentCode'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      centroidLat: (json['centroidLat'] as num?)?.toDouble(),
      centroidLng: (json['centroidLng'] as num?)?.toDouble(),
    );
  }
}
