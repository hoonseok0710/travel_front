import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/map_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/loading_view.dart';

class MapListScreen extends ConsumerStatefulWidget {
  const MapListScreen({super.key});

  @override
  ConsumerState<MapListScreen> createState() => _MapListScreenState();
}

class _MapListScreenState extends ConsumerState<MapListScreen>
    with WidgetsBindingObserver {

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 앱 시작 시 3초 후 자동 재시도 (콜드 스타트 대비)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) ref.invalidate(myMapsProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(myMapsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapsAsync = ref.watch(myMapsProvider);

    // 인증 에러 감지 시 로그인으로 이동
    ref.listen(myMapsProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) async {
          final accessToken = await TokenStorage.getAccessToken();
          if (accessToken == null) {
            if (context.mounted) context.go('/login');
            return;
          }

          // GET /maps에서 403은 토큰 만료로 인한 인증 실패로 처리
          if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
                await TokenStorage.clearTokens();
                if (context.mounted) context.go('/login');
          }
          },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 여행 지도'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading
                ? null
                : () async {
              setState(() => _isLoading = true);
              try {
                await TokenStorage.clearTokens();
                ref.invalidate(isLoggedInProvider);
                if (context.mounted) context.go('/login');
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          mapsAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) {
              print('=== MAP LIST ERROR ===');
              print('에러 타입: ${e.runtimeType}');
              print('에러 내용: $e');
              if (e is DioException) {
                print('상태 코드: ${e.response?.statusCode}');
                print('에러 타입: ${e.type}');
                print('에러 메시지: ${e.error}');
                print('응답 데이터: ${e.response?.data}');
                print('스택 트레이스: ${e.stackTrace}'); // 추가
              }
              print('스택 트레이스: ${StackTrace.current}'); // 추가

              return ErrorView(
                message: '지도를 불러오지 못했어요.',
                onRetry: () => ref.invalidate(myMapsProvider),
              );
            },
            data: (maps) {
              if (maps.isEmpty) {
                return const EmptyView(
                  icon: Icons.map_outlined,
                  message: '아직 여행 지도가 없어요.',
                  subMessage: '+ 버튼을 눌러 첫 번째 지도를 만들어보세요!',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: maps.length,
                itemBuilder: (context, index) {
                  final map = maps[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(map.regionName[0]),
                      ),
                      title: Text(map.title),
                      subtitle: Text(map.regionName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/maps/${map.id}'),
                    ),
                  );
                },
              );
            },
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        '로그아웃 중...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/maps/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}