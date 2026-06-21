import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/map_member_model.dart';
import '../repository/map_repository.dart';
import '../model/region_model.dart';
import '../model/region_pin_model.dart';
import '../model/travel_map_model.dart';
import '../../pin/model/pin_record_model.dart';
import '../../../core/network/dio_provider.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(ref.watch(dioProvider));
});

final regionsProvider = FutureProvider.family<List<RegionModel>, String?>((ref, type) async {
  return ref.watch(mapRepositoryProvider).getRegions(type: type);
});

final myMapsProvider = FutureProvider<List<TravelMapModel>>((ref) async {
  return ref.watch(mapRepositoryProvider).getMyMaps();
});

final mapDetailProvider = FutureProvider.family<TravelMapModel, int>((ref, mapId) async {
  return ref.watch(mapRepositoryProvider).getMap(mapId);
});

final regionPinsProvider = FutureProvider.family<List<RegionPinModel>, int>((ref, regionId) async {
  return ref.watch(mapRepositoryProvider).getRegionPins(regionId);
});

final pinRecordsProvider = FutureProvider.family<List<PinRecordModel>, int>((ref, mapId) async {
  return ref.watch(mapRepositoryProvider).getPinRecords(mapId);
});

final regionPinIdMapProvider = FutureProvider.family<Map<String, int>, int>(
      (ref, regionId) async {
    try {
      final pins = await ref.read(mapRepositoryProvider).getRegionPins(regionId);
      print('핀 목록 로드 성공: ${pins.length}개');
      final map = {
        for (final pin in pins)
          if (pin.svgId != null) pin.svgId!: pin.id
      };
      print('핀 맵: $map');
      return map;
    } catch (e) {
      print('핀 목록 로드 에러: $e');
      rethrow;
    }
  },
);

String _placeNameToSvgId(String placeName) {
  const map = {
    '서울': 'seoul', '부산': 'busan', '대구': 'daegu',
    '인천': 'incheon', '광주': 'gwangju', '대전': 'daejeon',
    '울산': 'ulsan', '세종': 'sejong', '제주': 'jeju',
    '수원': 'suwon', '용인': 'yongin', '고양': 'goyang',
    '성남': 'seongnam', '부천': 'bucheon', '안산': 'ansan',
    // 필요한 지역 추가
  };
  return map[placeName] ?? placeName.toLowerCase();
}

final mapMembersProvider = FutureProvider.family<List<MapMemberModel>, int>(
      (ref, mapId) async {
    return ref.watch(mapRepositoryProvider).getMembers(mapId);
  },
);

// 지도 표시 모드 (false: 대표사진, true: 랜덤)
final mapDisplayModeProvider = StateProvider<bool>((ref) => false);