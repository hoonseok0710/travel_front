import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/config/app_theme.dart';
import 'core/config/router.dart';
import 'features/map/util/svg_region_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 네비게이션 바 자동 숨김 설정
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky, // edgeToEdge → immersiveSticky
  );

  KakaoSdk.init(nativeAppKey: 'd48d53f3e1fe7f07a3a3047390030d7d');
  await SvgRegionCache.initialize();

  runApp(
    const ProviderScope(
      child: TravelApp(),
    ),
  );
}

class TravelApp extends ConsumerWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '여행기록소',
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}