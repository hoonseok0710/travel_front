class RegionPinModel {
  final int id;
  final String placeName;
  final String? svgId; // 추가, latitude/longitude 제거

  RegionPinModel({
    required this.id,
    required this.placeName,
    this.svgId,
  });

  factory RegionPinModel.fromJson(Map<String, dynamic> json) {
    return RegionPinModel(
      id: json['id'],
      placeName: json['placeName'],
      svgId: json['svgId'],
    );
  }
}