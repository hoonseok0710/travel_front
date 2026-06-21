import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';

class ReportRepository {
  final Dio _dio;
  ReportRepository(this._dio);

  Future<void> report({
    required int targetUserId,
    required String reason,
  }) async {
    await _dio.post('/reports', data: {
      'targetUserId': targetUserId,
      'reason': reason,
    });
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(dioProvider));
});