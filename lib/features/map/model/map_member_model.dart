class MapMemberModel {
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final String role;

  MapMemberModel({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.role,
  });

  factory MapMemberModel.fromJson(Map<String, dynamic> json) {
    return MapMemberModel(
      userId: json['userId'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
      role: json['role'],
    );
  }
}