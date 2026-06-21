import 'package:dio/dio.dart';
import '../model/pin_record_model.dart';

class PinRepository {
  final Dio _dio;

  PinRepository(this._dio);

  Future<PinRecordModel?> getPinRecord(int mapId, int regionPinId) async {
    try {
      final response = await _dio.get('/maps/$mapId/pins/$regionPinId');
      return PinRecordModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      // statusCode 또는 에러 메시지로 404 체크
      if (e.response?.statusCode == 404 ||
          e.error.toString().contains('찾을 수 없습니다')) {
        return null;
      }
      rethrow;
    }
  }

  Future<PinRecordModel> createPinRecord(int mapId, int regionPinId) async {
    final response = await _dio.post(
      '/maps/$mapId/pins/$regionPinId'
    );
    return PinRecordModel.fromJson(response.data['data']);
  }

  Future<void> deletePinRecord(int mapId, int regionPinId) async {
    await _dio.delete('/maps/$mapId/pins/$regionPinId');
  }

  Future<PinRecordModel?> getPinRecordByRegionPinId(
      int mapId, int regionPinId) async {
    try {
      final response = await _dio.get('/maps/$mapId/pins/$regionPinId');
      return PinRecordModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 ||
          e.error.toString().contains('찾을 수 없습니다')) {
        return null;
      }
      rethrow;
    }
  }
}