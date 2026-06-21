import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../model/photo_model.dart';

class PhotoRepository {
  final Dio _dio;

  PhotoRepository(this._dio);

  // 사진 목록 조회
  Future<List<PhotoModel>> getPhotos(int mapId, int pinRecordId) async {
    final response = await _dio.get('/maps/$mapId/pins/$pinRecordId/photos');
    return (response.data['data'] as List)
        .map((e) => PhotoModel.fromJson(e))
        .toList();
  }

  // 사진 업로드
  Future<List<PhotoModel>> uploadPhotos(
      int mapId, int pinRecordId, List<XFile> files) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ));
    }
    final response = await _dio.post(
      '/maps/$mapId/pins/$pinRecordId/photos',
      data: formData,
    );
    return (response.data['data'] as List)
        .map((e) => PhotoModel.fromJson(e))
        .toList();
  }

  // 사진 삭제
  Future<void> deletePhoto(int mapId, int pinRecordId, int photoId) async {
    await _dio.delete('/maps/$mapId/pins/$pinRecordId/photos/$photoId');
  }

  // 메인 사진 변경
  Future<void> updateMainPhoto(int mapId, int pinRecordId, int photoId) async {
    await _dio.patch(
      '/maps/$mapId/pins/$pinRecordId/photos/$photoId',
      data: {'isMain': true},
    );
  }

  Future<void> toggleLike(int mapId, int pinRecordId, int photoId) async {
    await _dio.post('/maps/$mapId/pins/$pinRecordId/photos/$photoId/like');
  }

  Future<void> updatePhotoTransform(
      int mapId, int pinRecordId, int photoId,
      double offsetX, double offsetY, double scale) async {
    await _dio.patch(
      '/maps/$mapId/pins/$pinRecordId/photos/$photoId/transform',
      data: {
        'offsetX': offsetX,
        'offsetY': offsetY,
        'scale': scale,
      },
    );
  }
}