import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/photo_repository.dart';
import '../model/photo_model.dart';
import '../../../core/network/dio_provider.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(dioProvider));
});

// 사진 목록 Provider
final photosProvider = FutureProvider.family<List<PhotoModel>, (int, int)>(
      (ref, args) async {
    final (mapId, pinRecordId) = args;
    try {
      final photos = await ref.watch(photoRepositoryProvider).getPhotos(mapId, pinRecordId);
      print('사진 로드 성공: mapId=$mapId, pinRecordId=$pinRecordId, ${photos.length}장');
      return photos;
    } catch (e) {
      print('사진 로드 에러: $e');
      rethrow;
    }
  },
);