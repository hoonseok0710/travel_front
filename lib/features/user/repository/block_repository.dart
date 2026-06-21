import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/block_model.dart';
import '../../../core/network/dio_provider.dart';

class BlockRepository {
  final Dio _dio;
  BlockRepository(this._dio);

  // 차단 목록 조회
  Future<List<BlockModel>> getBlockList() async {
    final response = await _dio.get('/blocks');
    return (response.data['data'] as List)
        .map((e) => BlockModel.fromJson(e))
        .toList();
  }

  // 차단
  Future<void> block(int blockedId) async {
    await _dio.post('/blocks/$blockedId');
  }

  // 차단 해제
  Future<void> unblock(int blockedId) async {
    await _dio.delete('/blocks/$blockedId');
  }
}

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository(ref.watch(dioProvider));
});

final blockListProvider = FutureProvider<List<BlockModel>>((ref) async {
  return ref.watch(blockRepositoryProvider).getBlockList();
});