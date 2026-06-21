import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient.getInstance();
});