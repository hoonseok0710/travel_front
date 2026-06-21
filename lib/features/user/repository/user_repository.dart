import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../model/user_model.dart';

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  // 내 프로필 조회
  Future<UserModel> getMe() async {
    final response = await _dio.get('/users/me');
    return UserModel.fromJson(response.data['data']);
  }

  // 닉네임 수정
  Future<UserModel> updateNickname(String nickname) async {
    final response = await _dio.patch(
      '/users/me',
      data: {'nickname': nickname},
    );
    return UserModel.fromJson(response.data['data']);
  }

  // 프로필 이미지 변경
  Future<UserModel> updateProfileImage(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final response = await _dio.patch(
      '/users/me/profile-image',
      data: formData,
    );
    return UserModel.fromJson(response.data['data']);
  }

  // 회원 탈퇴
  Future<void> deleteAccount() async {
    await _dio.delete('/users/me');
  }

  // 닉네임으로 유저 검색
  Future<UserModel> searchUser(String nickname) async {
    final response = await _dio.get(
      '/users/search',
      queryParameters: {'nickname': nickname},
    );
    return UserModel.fromJson(response.data['data']);
  }
}