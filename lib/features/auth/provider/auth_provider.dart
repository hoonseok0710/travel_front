import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';

// AuthRepository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

// 로그인 상태 Provider
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final token = await TokenStorage.getAccessToken();
  return token != null;
});