class PhotoModel {
  final int id;
  final String imageUrl;
  final bool isMain;
  final bool isLiked;
  final int displayOrder;
  final double offsetX; // 추가
  final double offsetY; // 추가
  final double scale;   // 추가

  PhotoModel({
    required this.id,
    required this.imageUrl,
    required this.isMain,
    required this.isLiked,
    required this.displayOrder,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scale = 1.0,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'],
      imageUrl: json['imageUrl'],
      isMain: json['main'] ?? false,
      isLiked: json['isLiked'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      offsetX: (json['offsetX'] ?? 0.0).toDouble(),
      offsetY: (json['offsetY'] ?? 0.0).toDouble(),
      scale: (json['scale'] ?? 1.0).toDouble(),
    );
  }
}