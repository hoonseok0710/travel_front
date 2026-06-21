class RegionModel {
  final int id;
  final String code;
  final String name;
  final String type;

  RegionModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      type: json['type'],
    );
  }
}