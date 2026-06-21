import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/user_repository.dart';
import '../model/user_model.dart';
import '../../../core/network/dio_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});

final myProfileProvider = FutureProvider<UserModel>((ref) async {
  return ref.watch(userRepositoryProvider).getMe();
});