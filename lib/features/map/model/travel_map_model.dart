class TravelMapModel {
  final int id;
  final int regionId; // 추가
  final String title;
  final String? coverImageUrl;
  final String regionCode;
  final String regionName;
  final String regionType;
  final String createdAt;

  TravelMapModel({
    required this.id,
    required this.regionId, // 추가
    required this.title,
    this.coverImageUrl,
    required this.regionCode,
    required this.regionName,
    required this.regionType,
    required this.createdAt,
  });

  factory TravelMapModel.fromJson(Map<String, dynamic> json) {
    return TravelMapModel(
      id: json['id'],
      regionId: json['regionId'], // 추가
      title: json['title'],
      coverImageUrl: json['coverImageUrl'],
      regionCode: json['regionCode'],
      regionName: json['regionName'],
      regionType: json['regionType'],
      createdAt: json['createdAt'],
    );
  }
}