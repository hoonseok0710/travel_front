import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../provider/map_provider.dart';
import 'korea_map_widget.dart';

final mapDisplayModeProvider = StateProvider<bool>((ref) => false);

class MapDetailScreen extends ConsumerStatefulWidget {
  final int mapId;

  const MapDetailScreen({super.key, required this.mapId});

  @override
  ConsumerState<MapDetailScreen> createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends ConsumerState<MapDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _photosLoaded = false;

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapDetailProvider(widget.mapId));
    final pinRecordsAsync = ref.watch(pinRecordsProvider(widget.mapId));
    final isRandomMode = ref.watch(mapDisplayModeProvider);

    // 모드 변경 시 사진 다시 로드
    ref.listen(mapDisplayModeProvider, (previous, next) {
      if (previous != next) setState(() => _photosLoaded = false);
    });

    // 핀 기록 변경 시 사진 다시 로드
    ref.listen(pinRecordsProvider(widget.mapId), (previous, next) {
      setState(() => _photosLoaded = false);
    });

    return mapAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('지도를 불러오지 못했어요.')),
      ),
      data: (map) {
        final pinIdMapAsync = ref.watch(regionPinIdMapProvider(map.regionId));

        return Scaffold(
          appBar: AppBar(
            title: Text(map.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showDisplayModeOptions(context, isRandomMode),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () => _saveToGallery(context, map.title),
              ),
              IconButton(
                icon: const Icon(Icons.people_outline),
                onPressed: () => context.push('/maps/${widget.mapId}/members'),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMapOptions(context, map.id),
              ),
            ],
          ),
          body: Stack(
            children: [
              pinRecordsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('기록을 불러오지 못했어요.')),
                data: (pinRecords) {
                  final visitedIds = pinRecords
                      .where((r) => r.svgId != null)
                      .map((r) => r.svgId!)
                      .toSet();

                  final random = Random();
                  final mainPhotoUrls = <String, String>{};
                  final photoTransforms = <String, (double, double, double)>{};

                  for (final r in pinRecords) {
                    if (r.svgId == null) continue;
                    if (isRandomMode && r.likedPhotos.isNotEmpty) {
                      final liked = r.likedPhotos[random.nextInt(r.likedPhotos.length)];
                      mainPhotoUrls[r.svgId!] = liked.imageUrl;
                      photoTransforms[r.svgId!] = (liked.offsetX, liked.offsetY, liked.scale);
                    } else if (r.mainPhotoUrl != null) {
                      mainPhotoUrls[r.svgId!] = r.mainPhotoUrl!;
                      photoTransforms[r.svgId!] = (r.mainOffsetX, r.mainOffsetY, r.mainScale);
                    }
                  }

                  // 사진 프리로드
                  if (!_photosLoaded && mainPhotoUrls.isNotEmpty) {
                    _preloadPhotos(mainPhotoUrls.values.toList());
                  } else if (mainPhotoUrls.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _photosLoaded = true);
                    });
                  }

                  // 사진 로딩 중
                  if (!_photosLoaded && mainPhotoUrls.isNotEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            '지도를 불러오고 있어요.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return pinIdMapAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) {
                      print('핀 정보 에러: $e');
                      return const Center(child: Text('핀 정보를 불러오지 못했어요.'));
                    },
                    data: (pinIdMap) => InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: Colors.white,
                          child: KoreaMapWidget(
                            visitedIds: visitedIds,
                            mainPhotoUrls: mainPhotoUrls,
                            photoTransforms: photoTransforms,
                            onRegionTap: (svgId) {
                              final regionPinId = pinIdMap[svgId];
                              if (regionPinId == null) return;
                              context.push('/maps/${widget.mapId}/pins/$regionPinId?svgId=$svgId');
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 로딩 오버레이
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _loadingMessage,
                            style: const TextStyle(
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
        );
      },
    );
  }

  Future<void> _preloadPhotos(List<String> photoUrls) async {
    try {
      await Future.wait(
        photoUrls.map((url) => precacheImage(NetworkImage(url), context)),
      );
      // 캐시 완료 후 렌더링 안정화 대기
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (_) {
      // 일부 실패해도 지도 표시
    } finally {
      if (mounted) setState(() => _photosLoaded = true);
    }
  }

  void _showDisplayModeOptions(BuildContext context, bool isRandomMode) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '지도 표시 설정',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: Icon(Icons.star, color: !isRandomMode ? Colors.black : Colors.grey),
              title: const Text('대표 사진만 출력'),
              subtitle: const Text('각 지역의 대표 사진을 표시해요.'),
              trailing: !isRandomMode ? const Icon(Icons.check, color: Colors.black) : null,
              onTap: () {
                ref.read(mapDisplayModeProvider.notifier).state = false;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: isRandomMode ? Colors.red : Colors.grey),
              title: const Text('좋아요 사진 랜덤 출력'),
              subtitle: const Text(
                '좋아요 누른 사진 중 랜덤으로 표시해요.\n좋아요 사진이 없으면 대표 사진을 표시해요.',
              ),
              trailing: isRandomMode ? const Icon(Icons.check, color: Colors.black) : null,
              onTap: () {
                ref.read(mapDisplayModeProvider.notifier).state = true;
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery(BuildContext context, String title) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장 중...'), duration: Duration(seconds: 1)),
    );

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();

      await Future.delayed(const Duration(milliseconds: 500));

      final image = await _screenshotController.capture(pixelRatio: 3.0);

      if (image == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('캡처에 실패했어요. 다시 시도해주세요.')),
          );
        }
        return;
      }

      await Gal.putImageBytes(image, album: '여행기록소');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 저장됐어요!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했어요.')),
        );
      }
    }
  }

  void _showMapOptions(BuildContext context, int mapId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('지도 삭제', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);

                setState(() {
                  _isLoading = true;
                  _loadingMessage = '지도를 삭제하고 있어요...';
                });

                try {
                  await ref.read(mapRepositoryProvider).deleteMap(mapId);
                  ref.invalidate(myMapsProvider);
                  if (context.mounted) context.go('/maps');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('지도 삭제에 실패했어요.')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}