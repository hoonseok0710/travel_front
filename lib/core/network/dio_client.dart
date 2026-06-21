import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../config/router.dart';
import '../storage/token_storage.dart';

class DioClient {
  static Dio getInstance() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(dio));
    dio.interceptors.add(_ErrorInterceptor());
    return dio;
  }
}

class _RetryRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _RetryRequest(this.options, this.handler);
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<_RetryRequest> _pendingRequests = [];

  _AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) GoRouter.of(context).go('/login');
    });
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null) {
        await TokenStorage.clearTokens();
        _redirectToLogin();
        handler.next(err);
        return;
      }

      // 이미 갱신 중이면 대기열에 추가
      if (_isRefreshing) {
        _pendingRequests.add(_RetryRequest(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;

      try {
        final response = await Dio().post(
          '${AppConfig.baseUrl}/auth/reissue',
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['data']['accessToken'];
        final newRefreshToken = response.data['data']['refreshToken'];

        await TokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // 대기 중인 요청들 재시도
        for (final pending in _pendingRequests) {
          pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final retryResponse = await dio.fetch(pending.options);
            pending.handler.resolve(retryResponse);
          } catch (e) {
            pending.handler.next(err);
          }
        }
        _pendingRequests.clear();

        // 현재 요청 재시도
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (e) {
        // 갱신 실패 시 대기 중인 요청들도 실패 처리
        for (final pending in _pendingRequests) {
          pending.handler.next(err);
        }
        _pendingRequests.clear();

        await TokenStorage.clearTokens();
        _redirectToLogin();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(DioException(
          requestOptions: err.requestOptions,
          error: '서버 응답이 너무 늦어요. 잠시 후 다시 시도해주세요.',
          type: err.type,
        ));
        break;
      case DioExceptionType.connectionError:
        handler.next(DioException(
          requestOptions: err.requestOptions,
          error: '인터넷 연결을 확인해주세요.',
          type: err.type,
        ));
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;

        // response.data가 Map일 때만 message 접근
        final serverMessage = (err.response?.data is Map)
            ? err.response?.data['message']
            : null;

        final message = switch (statusCode) {
          400 => serverMessage ?? '잘못된 요청이에요.',
          401 => '인증이 필요해요.',
          403 => '접근 권한이 없어요.',
          404 => '요청한 정보를 찾을 수 없어요.',
          409 => serverMessage ?? '이미 존재하는 정보예요.',
          500 => '서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.',
          _ => serverMessage ?? '오류가 발생했어요.',
        };

        handler.next(DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: message,
          type: err.type,
        ));
        break;
      default:
        handler.next(err);
    }
  }
}