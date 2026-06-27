import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../map/util/svg_region_cache.dart';
import '../model/pin_record_model.dart';
import '../provider/pin_provider.dart';
import '../../photo/provider/photo_provider.dart';
import '../../photo/model/photo_model.dart';
import '../../map/provider/map_provider.dart';

class PinRecordScreen extends ConsumerStatefulWidget {
  final int mapId;
  final int regionPinId;
  final String svgId;

  const PinRecordScreen({
    super.key,
    required this.mapId,
    required this.regionPinId,
    required this.svgId,
  });

  @override
  ConsumerState<PinRecordScreen> createState() => _PinRecordScreenState();
}

class _PinRecordScreenState extends ConsumerState<PinRecordScreen> {
  final _picker = ImagePicker();
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickAndUpload(int pinRecordId) async {
    final files = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (files.isEmpty) return;

    const maxFileSize = 10 * 1024 * 1024;
    for (final file in files) {
      final bytes = await file.length();
      if (bytes > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진 크기는 10MB 이하여야 해요.')),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = '사진을 업로드하고 있어요...'; // 추가
    });

    try {
      final uploadedPhotos = await ref.read(photoRepositoryProvider)
          .uploadPhotos(widget.mapId, pinRecordId, files);

      ref.invalidate(photosProvider((widget.mapId, pinRecordId)));
      ref.invalidate(pinRecordsProvider(widget.mapId));

      if (uploadedPhotos.isNotEmpty && mounted) {
        _openTransformEditor(pinRecordId, uploadedPhotos.first.id,
            uploadedPhotos.first.imageUrl, 0.0, 0.0, 1.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 업로드에 실패했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openTransformEditor(int pinRecordId, int photoId, String photoUrl, double offsetX, double offsetY, double scale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) => _PhotoTransformEditor(
        mapId: widget.mapId,
        pinRecordId: pinRecordId,
        photoId: photoId, // 추가
        regionPinId: widget.regionPinId,
        svgId: widget.svgId,
        photoUrl: photoUrl,
        initialOffsetX: offsetX,
        initialOffsetY: offsetY,
        initialScale: scale,
        onSaved: () {
          ref.invalidate(pinRecordDetailProvider((widget.mapId, widget.regionPinId)));
          ref.invalidate(pinRecordsProvider(widget.mapId));
        },
      ),
    );
  }

  Future<void> _deletePhoto(int pinRecordId, int photoId) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = '사진을 삭제하고 있어요...'; // 추가
    });
    try {
      await ref.read(photoRepositoryProvider).deletePhoto(
          widget.mapId, pinRecordId, photoId);
      ref.invalidate(photosProvider((widget.mapId, pinRecordId)));
      ref.invalidate(pinRecordsProvider(widget.mapId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 삭제에 실패했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadNew() async {
    final files = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (files.isEmpty) return;

    const maxFileSize = 10 * 1024 * 1024;
    for (final file in files) {
      final bytes = await file.length();
      if (bytes > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진 크기는 10MB 이하여야 해요.')),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = '사진을 업로드하고 있어요...'; // 추가
    });

    try {
      PinRecordModel? pinRecord = await ref.read(pinRepositoryProvider)
          .getPinRecordByRegionPinId(widget.mapId, widget.regionPinId);

      if (pinRecord == null) {
        await ref.read(pinRepositoryProvider)
            .createPinRecord(widget.mapId, widget.regionPinId);
        pinRecord = await ref.read(pinRepositoryProvider)
            .getPinRecordByRegionPinId(widget.mapId, widget.regionPinId);
      }

      if (pinRecord == null) throw Exception('핀 기록 생성 실패');

      final uploadedPhotos = await ref.read(photoRepositoryProvider)
          .uploadPhotos(widget.mapId, pinRecord.id, files);

      ref.invalidate(pinRecordDetailProvider((widget.mapId, widget.regionPinId)));
      ref.invalidate(pinRecordsProvider(widget.mapId));

      if (uploadedPhotos.isNotEmpty && mounted) {
        _openTransformEditor(
          pinRecord.id,
          uploadedPhotos.first.id,
          uploadedPhotos.first.imageUrl,
          0.0, 0.0, 1.0,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 업로드에 실패했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptions(PhotoModel photo, int pinRecordId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 좋아요 토글
            ListTile(
              leading: Icon(
                photo.isLiked ? Icons.favorite : Icons.favorite_border,
                color: photo.isLiked ? Colors.red : null,
              ),
              title: Text(photo.isLiked ? '좋아요 취소' : '좋아요'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(photoRepositoryProvider)
                    .toggleLike(widget.mapId, pinRecordId, photo.id);
                ref.invalidate(photosProvider((widget.mapId, pinRecordId)));
                ref.invalidate(pinRecordsProvider(widget.mapId));
              },
            ),

            // 지도 사진 위치 조정 추가
            ListTile(
              leading: const Icon(Icons.crop_free),
              title: const Text('지도 사진 위치 조정'),
              onTap: () {
                Navigator.pop(context);
                _openTransformEditor(
                  pinRecordId,
                  photo.id,
                  photo.imageUrl,
                  photo.offsetX,
                  photo.offsetY,
                  photo.scale,
                );
              },
            ),

            // 대표 사진 설정
            if (!photo.isMain)
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('대표 사진으로 설정'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(photoRepositoryProvider).updateMainPhoto(
                      widget.mapId, pinRecordId, photo.id);
                  ref.invalidate(photosProvider((widget.mapId, pinRecordId)));
                  ref.invalidate(pinRecordsProvider(widget.mapId));
                },
              ),

            // 사진 삭제
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('사진 삭제', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deletePhoto(pinRecordId, photo.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinRecordAsync = ref.watch(
      pinRecordDetailProvider((widget.mapId, widget.regionPinId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_svgIdToKorean(widget.svgId)),
        actions: [
          pinRecordAsync.whenData((pinRecord) {
            if (pinRecord == null) return const SizedBox();
            return IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deletePinRecord(pinRecord.id),
            );
          }).value ?? const SizedBox(),
        ],
      ),
      body: Stack(
        children: [
          pinRecordAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('불러오지 못했어요.')),
            data: (pinRecord) {
              if (pinRecord == null) return _buildEmptyView();
              return _buildDetailView(pinRecord);
            },
          ),

          // 로딩 오버레이
          if (_isLoading)
            Container(
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
        ],
      ),
    );
  }

  Future<void> _deletePinRecord(int pinRecordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('핀 기록 삭제'),
        content: const Text('이 지역의 기록과 사진이 모두 삭제돼요.\n정말 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(pinRepositoryProvider).deletePinRecord(
          widget.mapId, widget.regionPinId);
      ref.invalidate(pinRecordsProvider(widget.mapId));
      ref.invalidate(pinRecordDetailProvider((widget.mapId, widget.regionPinId)));
      ref.invalidate(photosProvider((widget.mapId, pinRecordId)));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했어요.')),
        );
      }
    }
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 영역
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),

            // 제목
            const Text(
              '아직 기록이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // 설명
            Text(
              '사진을 추가해\n이 지역의 여행을 기록해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pickAndUploadNew,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '사진 추가하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(pinRecord) {
    final photosAsync = ref.watch(photosProvider((widget.mapId, pinRecord.id)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _pickAndUpload(pinRecord.id),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('사진 추가'),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),

          photosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('사진을 불러오지 못했어요.'),
            data: (photos) {
              if (photos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('아직 사진이 없어요.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final sortedPhotos = [...photos]
                ..sort((a, b) {
                  if (a.isMain) return -1;
                  if (b.isMain) return 1;
                  return a.displayOrder.compareTo(b.displayOrder);
                });

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: sortedPhotos.length,
                itemBuilder: (context, index) {
                  final photo = sortedPhotos[index];
                  return _buildPhotoItem(photo, pinRecord.id);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(PhotoModel photo, int pinRecordId) {
    return GestureDetector(
      onTap: () => _showPhotoOptions(photo, pinRecordId),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            photo.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              );
            },
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          ),
          if (photo.isMain)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('대표',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          // 좋아요 표시 추가
          if (photo.isLiked)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.favorite, color: Colors.red, size: 16),
            ),
        ],
      ),
    );
  }

  String _svgIdToKorean(String svgId) {
    const map = {
      'seoul': '서울', 'busan': '부산', 'daegu': '대구', 'incheon': '인천', 'gwangju': '광주',
      'daejeon': '대전', 'ulsan': '울산', 'sejong': '세종', 'gyeonggi': '광주', 'suwon': '수원',
      'goyang': '고양', 'yongin': '용인', 'seongnam': '성남', 'bucheon': '부천', 'ansan': '안산',
      'anyang': '안양', 'namyangju': '남양주', 'hwaseong': '화성', 'pyeongtaek': '평택',
      'uijeongbu': '의정부', 'paju': '파주', 'siheung': '시흥', 'gimpo': '김포', 'gwangmyeong': '광명',
      'gapyeong': '가평', 'yangpyeong': '양평', 'icheon': '이천', 'yeoju': '여주', 'anseong': '안성',
      'osan': '오산', 'hanam': '하남', 'guri': '구리', 'uiwang': '의왕', 'gunpo': '군포', 'gwacheon': '과천',
      'dongducheon': '동두천', 'yangju': '양주', 'pocheon': '포천', 'yeoncheon': '연천', 'ganghwa': '강화',
      'chuncheon': '춘천', 'wonju': '원주', 'gangneung': '강릉', 'donghae': '동해', 'taebaek': '태백',
      'sokcho': '속초', 'samcheok': '삼척', 'hongcheon': '홍천', 'hoengseong': '횡성', 'yeongwol': '영월',
      'pyeongchang': '평창', 'Jeongseon': '정선', 'cheorwon': '철원', 'hwacheon': '화천', 'yanggu': '양구',
      'inje': '인제', 'yangyang': '양양', '고성군': '고성', 'cheonan': '천안', 'gongju': '공주', 'asan': '아산',
      'seosan': '서산', 'nonsan': '논산', 'gyeryong': '계룡', 'dangjin': '당진', 'geumsan': '금산', 'buyeo': '부여',
      'seocheon': '서천', 'cheongyang': '청양', 'hongseong': '홍성', 'yesan': '예산', 'taean': '태안',
      'cheongju': '청주', 'chungju': '충주', 'jecheon': '제천', 'boeun': '보은', 'okcheon': '옥천', 'yeongdong': '영동',
      'jeungpyeong': '증평', 'jincheon': '진천', 'goesan': '괴산', 'eumseong': '음성', 'danyang': '단양', 'jeonju': '전주',
      'gunsan': '군산', 'iksan': '익산', 'jeongeup': '정읍', 'namwon': '남원', 'gimje': '김제', 'wanju': '완주',
      'jinan': '진안', 'muju': '무주', 'jangsu': '장수', 'imsil': '임실', 'sunchang': '순창', 'gochang': '고창',
      'buan': '부안', 'mokpo': '목포', 'yeosu': '여수', 'suncheon': '순천', 'naju': '나주', 'gwangyang': '광양',
      'damyang': '담양', 'gokseong': '곡성', 'gurye': '구례', 'hwasun': '화순', 'jangheung': '장흥', 'gangjin': '강진',
      'haenam': '해남', 'yeongam': '영암', 'muan': '무안', 'hampyeong': '함평', 'yeonggwang': '영광', 'jangseong': '장성',
      'wando': '완도', 'jindo': '진도', 'sinan': '신안', 'boseong': '보성', 'goheung': '고흥', 'jeju': '제주',
      'seogwipo': '서귀포', 'pohang': '포항', 'gyeongju': '경주', 'gumi': '구미', 'andong': '안동', 'gimcheon': '김천',
      'mungyeong': '문경', 'sangju': '상주', 'yeongju': '영주', 'yeongcheon': '영천', 'gyeongsan': '경산', 'chilgok': '칠곡',
      'seongju': '성주', 'goryeong': '고령', 'uiseong': '의성', 'cheongsong': '청송', 'yeongyang': '영양', 'yeongdeok': '영덕',
      'cheongdo': '청도', 'gunwi': '군위', 'uljin': '울진', 'ulleung': '울릉', 'bonghwa': '봉화', 'yecheon': '예천', 'changwon': '창원',
      'jinju': '진주', 'tongyeong': '통영', 'sacheon': '사천', 'gimhae': '김해', 'miryang': '밀양', 'geoje': '거제', 'yangsan': '양산',
      'changnyeong': '창녕', 'haman': '함안', 'uiryeong': '의령', 'hapcheon': '합천', 'geochang': '거창', 'hamyang': '함양',
      'sancheong': '산청', 'hadong': '하동', 'namhae': '남해', 'goseong': '고성', 'boryeong': '보령', 'dokdo': '독도'
    };
    return map[svgId] ?? svgId;
  }
}

class _PhotoTransformEditor extends ConsumerStatefulWidget {
  final int mapId;
  final int pinRecordId;
  final int regionPinId;
  final String svgId; // 추가
  final int photoId; // 추가
  final String photoUrl;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;
  final VoidCallback onSaved;

  const _PhotoTransformEditor({
    required this.mapId,
    required this.pinRecordId,
    required this.regionPinId,
    required this.svgId, // 추가
    required this.photoId,
    required this.photoUrl,
    required this.initialOffsetX,
    required this.initialOffsetY,
    required this.initialScale,
    required this.onSaved,
  });

  @override
  ConsumerState<_PhotoTransformEditor> createState() =>
      _PhotoTransformEditorState();
}

class _PhotoTransformEditorState extends ConsumerState<_PhotoTransformEditor> {
  late double _offsetX;
  late double _offsetY;
  late double _scale;
  double _previewWidth = 0;
  double _previewHeight = 0;
  double _fitScale = 1.0;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    _offsetX = widget.initialOffsetX;
    _offsetY = widget.initialOffsetY;
    _scale = widget.initialScale;
    _lastScale = widget.initialScale;
  }

  Future<void> _save() async {
    if (_fitScale == 0) return;
    final regionPath = SvgRegionCache.getPath(widget.svgId);
    if (regionPath == null) return;
    final bounds = regionPath.getBounds();

    final rW = bounds.width * _fitScale;
    final rH = bounds.height * _fitScale;

    final normalizedOffsetX = _offsetX / rW;
    final normalizedOffsetY = _offsetY / rH;

    // pinRecord → photo 기준으로 변경
    await ref.read(photoRepositoryProvider).updatePhotoTransform(
        widget.mapId, widget.pinRecordId, widget.photoId,
        normalizedOffsetX, normalizedOffsetY, _scale);

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final regionPath = SvgRegionCache.getPath(widget.svgId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '사진 위치 조정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '드래그로 위치를, 두 손가락으로 크기를 조정해요.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (regionPath == null) {
                  return const Center(child: Text('지역 정보를 불러오지 못했어요.'));
                }

                final bounds = regionPath.getBounds();
                final fitScaleX = constraints.maxWidth / bounds.width;
                final fitScaleY = constraints.maxHeight / bounds.height;
                final fitScale = (fitScaleX < fitScaleY ? fitScaleX : fitScaleY) * 0.9;

                // 지역 표시 크기
                final rW = bounds.width * fitScale;
                final rH = bounds.height * fitScale;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_previewWidth != constraints.maxWidth ||
                      _previewHeight != constraints.maxHeight ||
                      _fitScale != fitScale) {
                    setState(() {
                      _previewWidth = constraints.maxWidth;
                      _previewHeight = constraints.maxHeight;
                      _fitScale = fitScale;
                    });
                  }
                });

                final regionOffsetX = (constraints.maxWidth - rW) / 2 - bounds.left * fitScale;
                final regionOffsetY = (constraints.maxHeight - rH) / 2 - bounds.top * fitScale;

                final matrix = Matrix4.identity()
                  ..translate(regionOffsetX, regionOffsetY)
                  ..scale(fitScale);
                final screenPath = regionPath.transform(matrix.storage);

                // 이미지 크기를 지역 크기가 아닌 지역의 긴 쪽 기준으로 설정
                final imgW = rW * _scale;
                final imgH = rH * _scale;
                final imgLeft = constraints.maxWidth / 2 + _offsetX - imgW / 2;
                final imgTop = constraints.maxHeight / 2 + _offsetY - imgH / 2;

                return GestureDetector(
                  onScaleStart: (d) {
                    // 제스처 시작 시 현재 scale 저장
                    _lastScale = _scale;
                  },
                  onScaleUpdate: (d) => setState(() {
                    // 이동 처리 - 부드럽게
                    _offsetX += d.focalPointDelta.dx;
                    _offsetY += d.focalPointDelta.dy;

                    // 확대/축소 - 시작 시점 기준으로 계산 (더 자연스럽게)
                    if (d.pointerCount >= 2) {
                      _scale = (_lastScale * d.scale).clamp(0.5, 5.0);
                    }
                  }),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 배경
                        Container(color: Colors.grey[200]),

                        // 사진 - SVG 지역 모양으로 클리핑
                        ClipPath(
                          clipper: _ScreenPathClipper(screenPath),
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.hardEdge, // 추가
                            children: [
                              Positioned(
                                left: imgLeft,
                                top: imgTop,
                                width: imgW,
                                height: imgH,
                                child: Image.network(
                                  widget.photoUrl,
                                  fit: BoxFit.contain, // 원본 비율 유지
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 지역 바깥 어둡게 + 경계선
                        CustomPaint(
                          painter: _RegionOverlayPainter(screenPath),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SVG 경로로 클리핑
class _ScreenPathClipper extends CustomClipper<Path> {
  final Path path;
  _ScreenPathClipper(this.path);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_ScreenPathClipper old) => old.path != path;
}

// 지역 바깥 어둡게 + 경계선
class _RegionOverlayPainter extends CustomPainter {
  final Path regionPath;
  _RegionOverlayPainter(this.regionPath);

  @override
  void paint(Canvas canvas, Size size) {
    // 바깥 어둡게
    final fullRect = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final outside = Path.combine(
        PathOperation.difference, fullRect, regionPath);
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // 경계선
    canvas.drawPath(
      regionPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RegionOverlayPainter old) => false;
}