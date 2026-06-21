import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/pin_repository.dart';
import '../model/pin_record_model.dart';
import '../../../core/network/dio_provider.dart';

final pinRepositoryProvider = Provider<PinRepository>((ref) {
  return PinRepository(ref.watch(dioProvider));
});

final pinRecordDetailProvider = FutureProvider.family<PinRecordModel?, (int, int)>(
      (ref, args) async {
    final (mapId, regionPinId) = args;
    return ref.watch(pinRepositoryProvider).getPinRecord(mapId, regionPinId);
  },
);