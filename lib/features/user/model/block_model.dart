class BlockModel {
  final int userId;
  final String nickname;
  final String? profileImageUrl;

  BlockModel({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
  });

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      userId: json['userId'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}