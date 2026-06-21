import 'package:dio/dio.dart';
import '../model/map_member_model.dart';
import '../model/region_model.dart';
import '../model/region_pin_model.dart';
import '../model/travel_map_model.dart';
import '../../pin/model/pin_record_model.dart';

class MapRepository {
  final Dio _dio;

  MapRepository(this._dio);

  // 지역 목록 조회
  Future<List<RegionModel>> getRegions({String? type}) async {
    final response = await _dio.get(
      '/regions',
      queryParameters: type != null ? {'type': type} : null,
    );
    return (response.data['data'] as List)
        .map((e) => RegionModel.fromJson(e))
        .toList();
  }

  // 특정 지역 핀 목록 조회
  Future<List<RegionPinModel>> getRegionPins(int regionId) async {
    final response = await _dio.get('/regions/$regionId/pins');
    return (response.data['data'] as List)
        .map((e) => RegionPinModel.fromJson(e))
        .toList();
  }

  // 내 지도 목록 조회
  Future<List<TravelMapModel>> getMyMaps() async {
    final response = await _dio.get('/maps');
    print('=== getMyMaps 응답 ===');
    print('response.data 타입: ${response.data.runtimeType}');
    print('response.data: ${response.data}');
    return (response.data['data'] as List)
        .map((e) => TravelMapModel.fromJson(e))
        .toList();
  }

  // 지도 상세 조회
  Future<TravelMapModel> getMap(int mapId) async {
    final response = await _dio.get('/maps/$mapId');
    return TravelMapModel.fromJson(response.data['data']);
  }

  // 지도 생성
  Future<TravelMapModel> createMap({
    required int regionId,
    required String title,
  }) async {
    final response = await _dio.post('/maps', data: {
      'regionId': regionId,
      'title': title,
    });
    return TravelMapModel.fromJson(response.data['data']);
  }

  // 지도 삭제
  Future<void> deleteMap(int mapId) async {
    await _dio.delete('/maps/$mapId');
  }

  // 핀 기록 목록 조회
  Future<List<PinRecordModel>> getPinRecords(int mapId) async {
    final response = await _dio.get('/maps/$mapId/pins');
    return (response.data['data'] as List)
        .map((e) => PinRecordModel.fromJson(e))
        .toList();
  }

  // 멤버 목록 조회
  Future<List<MapMemberModel>> getMembers(int mapId) async {
    final response = await _dio.get('/maps/$mapId/members');
    return (response.data['data'] as List)
        .map((e) => MapMemberModel.fromJson(e))
        .toList();
  }

  // 멤버 초대
  Future<void> inviteMember(int mapId, int userId) async {
    await _dio.post('/maps/$mapId/members', data: {'userId': userId});
  }

  // 멤버 삭제
  Future<void> removeMember(int mapId, int userId) async {
    await _dio.delete('/maps/$mapId/members/$userId');
  }
}