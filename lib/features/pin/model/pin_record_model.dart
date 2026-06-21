class LikedPhotoInfo {
  final String imageUrl;
  final double offsetX;
  final double offsetY;
  final double scale;

  LikedPhotoInfo({
    required this.imageUrl,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
  });

  factory LikedPhotoInfo.fromJson(Map<String, dynamic> json) {
    return LikedPhotoInfo(
      imageUrl: json['imageUrl'],
      offsetX: (json['offsetX'] ?? 0.0).toDouble(),
      offsetY: (json['offsetY'] ?? 0.0).toDouble(),
      scale: (json['scale'] ?? 1.0).toDouble(),
    );
  }
}

class PinRecordModel {
  final int id;
  final int regionPinId;
  final String? svgId;
  final String placeName;
  final String? mainPhotoUrl;
  final double mainOffsetX; // 추가
  final double mainOffsetY; // 추가
  final double mainScale;   // 추가
  final List<LikedPhotoInfo> likedPhotos; // 변경
  final String createdAt;

  PinRecordModel({
    required this.id,
    required this.regionPinId,
    this.svgId,
    required this.placeName,
    this.mainPhotoUrl,
    this.mainOffsetX = 0.0,
    this.mainOffsetY = 0.0,
    this.mainScale = 1.0,
    this.likedPhotos = const [],
    required this.createdAt,
  });

  factory PinRecordModel.fromJson(Map<String, dynamic> json) {
    return PinRecordModel(
      id: json['id'],
      regionPinId: json['regionPinId'],
      svgId: json['svgId'],
      placeName: json['placeName'],
      mainPhotoUrl: json['mainPhotoUrl'],
      mainOffsetX: (json['mainOffsetX'] ?? 0.0).toDouble(),
      mainOffsetY: (json['mainOffsetY'] ?? 0.0).toDouble(),
      mainScale: (json['mainScale'] ?? 1.0).toDouble(),
      likedPhotos: (json['likedPhotos'] as List? ?? [])
          .map((e) => LikedPhotoInfo.fromJson(e))
          .toList(),
      createdAt: json['createdAt'],
    );
  }
}