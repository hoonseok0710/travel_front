import 'package:dio/dio.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../model/token_model.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  // 회원가입
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await _dio.post('/auth/signup', data: {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
  }

  // 로그인
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    // 응답 데이터 검증
    final data = response.data['data'];
    if (data == null) throw Exception('로그인 응답이 올바르지 않아요.');

    final token = TokenModel.fromJson(data);
    if (token.accessToken.isEmpty || token.refreshToken.isEmpty) {
      throw Exception('토큰이 올바르지 않아요.');
    }

    await TokenStorage.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
  }

  // 로그아웃 - 서버 실패해도 로컬 토큰은 반드시 삭제
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // 서버 오류가 나도 로컬 토큰은 삭제
    } finally {
      await TokenStorage.clearTokens();
    }
  }

  // 토큰 재발급
  Future<void> reissue() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('refresh token이 없어요.');

    final response = await _dio.post('/auth/reissue', data: {
      'refreshToken': refreshToken,
    });

    final data = response.data['data'];
    if (data == null) throw Exception('토큰 재발급 응답이 올바르지 않아요.');

    final token = TokenModel.fromJson(data);
    await TokenStorage.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
  }

  Future<void> kakaoLogin() async {
    // 카카오톡 설치 여부 확인
    String kakaoAccessToken;

    if (await isKakaoTalkInstalled()) {
      // 카카오톡으로 로그인
      final token = await UserApi.instance.loginWithKakaoTalk();
      kakaoAccessToken = token.accessToken;
    } else {
      // 카카오 계정으로 로그인
      final token = await UserApi.instance.loginWithKakaoAccount();
      kakaoAccessToken = token.accessToken;
    }

    // 백엔드로 카카오 액세스 토큰 전송
    final response = await _dio.post('/auth/kakao', data: {
      'accessToken': kakaoAccessToken,
    });

    final token = TokenModel.fromJson(response.data['data']);
    await TokenStorage.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
  }
}