class UserModel {
  final int id;
  final String email;
  final String nickname;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}