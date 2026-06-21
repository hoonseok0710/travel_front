import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

class RegionPath {
  final String id;
  final Path path;

  RegionPath({required this.id, required this.path});
}

class KoreaMapWidget extends StatefulWidget {
  final Set<String> visitedIds;
  final Map<String, String> mainPhotoUrls;
  final Map<String, (double, double, double)> photoTransforms;
  final Function(String regionId) onRegionTap;

  const KoreaMapWidget({
    super.key,
    required this.visitedIds,
    required this.mainPhotoUrls,
    required this.photoTransforms,
    required this.onRegionTap,
  });

  @override
  State<KoreaMapWidget> createState() => _KoreaMapWidgetState();
}

class _KoreaMapWidgetState extends State<KoreaMapWidget> with TickerProviderStateMixin {
  List<RegionPath> _regions = [];
  Map<String, Offset> _regionCenters = {};
  static const double _svgWidth = 509;
  static const double _svgHeight = 716.1;

  // 탭된 지역 애니메이션
  String? _tappedRegionId;
  late AnimationController _tapController;
  late Animation<double> _tapAnimation;

  // 방문 지역 페이드인
  final Map<String, AnimationController> _fadeControllers = {};
  final Map<String, Animation<double>> _fadeAnimations = {};
  Set<String> _previousVisitedIds = {};

  @override
  void initState() {
    super.initState();
    _parseSvg();

    // 탭 애니메이션 (확대 후 원복) - 시간 늘리기
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 150 → 300
    );
    _tapAnimation = Tween<double>(begin: 1.0, end: 1.5).animate( // 1.3 → 1.5
      CurvedAnimation(parent: _tapController, curve: Curves.elasticOut), // easeOut → elasticOut
    );
  }

  @override
  void didUpdateWidget(KoreaMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 새로 방문한 지역 페이드인 애니메이션 시작
    for (final id in widget.visitedIds) {
      if (!_previousVisitedIds.contains(id) && !_fadeControllers.containsKey(id)) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        );
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeIn),
        );
        _fadeControllers[id] = controller;
        _fadeAnimations[id] = animation;
        controller.forward();
      }
    }
    _previousVisitedIds = Set.from(widget.visitedIds);
  }

  @override
  void dispose() {
    _tapController.dispose();
    for (final c in _fadeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _parseSvg() async {
    final svgString = await rootBundle.loadString('assets/maps/korea.svg');
    final document = XmlDocument.parse(svgString);
    final regions = <RegionPath>[];

    for (final path in document.findAllElements('path')) {
      final id = path.getAttribute('id') ?? '';
      final d = path.getAttribute('d') ?? '';
      final transform = path.getAttribute('transform') ?? '';

      if (id.isEmpty || id.startsWith('path') || d.isEmpty) continue;
      if (['Layer_1', 'defs5', 'namedview5', 'style1', 'trash'].contains(id)) continue;

      try {
        final flutterPath = _parseSvgPath(d);
        final translatedPath = _applyTransform(flutterPath, transform);
        regions.add(RegionPath(id: id, path: translatedPath));
      } catch (_) {}
    }

    setState(() => _regions = regions);
    _calculateCenters();
  }

  // SVG 파싱 완료 후 중심점 계산
  void _calculateCenters() {
    final centers = <String, Offset>{};
    for (final region in _regions) {
      final bounds = region.path.getBounds();
      centers[region.id] = Offset(
        bounds.left + bounds.width / 2,
        bounds.top + bounds.height / 2,
      );
    }
    setState(() => _regionCenters = centers);
  }

  Path _applyTransform(Path path, String transform) {
    if (transform.isEmpty) return path;
    final translateRegex = RegExp(r'translate\(([^,)]+)(?:,([^)]+))?\)');
    final match = translateRegex.firstMatch(transform);
    if (match == null) return path;
    final tx = double.tryParse(match.group(1)?.trim() ?? '0') ?? 0;
    final ty = double.tryParse(match.group(2)?.trim() ?? '0') ?? 0;
    if (tx == 0 && ty == 0) return path;
    final matrix = Matrix4.identity()..translate(tx, ty);
    return path.transform(matrix.storage);
  }

  // SVG path 데이터 → Flutter Path 변환
  Path _parseSvgPath(String d) {
    final converter = _SvgPathConverter();
    writeSvgPathDataToPath(d, converter);
    return converter.path;
  }

  // 탭한 좌표 → SVG 좌표 변환 후 지역 감지
  void _onTapUp(TapUpDetails details, BoxConstraints constraints) {
    final scaleX = constraints.maxWidth / _svgWidth;
    final scaleY = constraints.maxHeight / _svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (constraints.maxWidth - _svgWidth * scale) / 2;
    final offsetY = (constraints.maxHeight - _svgHeight * scale) / 2;

    final svgX = (details.localPosition.dx - offsetX) / scale;
    final svgY = (details.localPosition.dy - offsetY) / scale;
    final point = Offset(svgX, svgY);

    for (final region in _regions) {
      if (region.path.contains(point)) {
        setState(() => _tappedRegionId = region.id);
        _tapController.forward().then((_) {
          _tapController.reverse().then((_) {
            setState(() => _tappedRegionId = null);
          });
        });
        widget.onRegionTap(region.id);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_regions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / _svgWidth;
        final scaleY = constraints.maxHeight / _svgHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;
        final offsetX = (constraints.maxWidth - _svgWidth * scale) / 2;
        final offsetY = (constraints.maxHeight - _svgHeight * scale) / 2;

        return GestureDetector(
          onTapUp: (details) => _onTapUp(details, constraints),
          child: Stack(
            children: [
              // SVG 지도
              AnimatedBuilder(
                animation: _tapAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _KoreaMapPainter(
                      regions: _regions,
                      visitedIds: widget.visitedIds,
                      photoUrls: widget.mainPhotoUrls,
                      scale: scale,
                      offsetX: offsetX,
                      offsetY: offsetY,
                      tappedRegionId: _tappedRegionId,
                      tapScale: _tapAnimation.value,
                      fadeAnimations: _fadeAnimations,
                    ),
                  );
                },
              ),

// 대표 사진 오버레이
              ..._regions
                  .where((r) => widget.mainPhotoUrls.containsKey(r.id))
                  .map((region) {
                final photoUrl = widget.mainPhotoUrls[region.id]!;
                final transform = widget.photoTransforms[region.id] ?? (0.0, 0.0, 1.0);
                final (normalizedOffsetX, normalizedOffsetY, pScale) = transform;

                final bounds = region.path.getBounds();
                final screenLeft = bounds.left * scale + offsetX;
                final screenTop = bounds.top * scale + offsetY;
                final screenWidth = bounds.width * scale;
                final screenHeight = bounds.height * scale;

                final actualOffsetX = normalizedOffsetX * screenWidth;
                final actualOffsetY = normalizedOffsetY * screenHeight;

                final imgW = screenWidth * pScale;
                final imgH = screenHeight * pScale;
                final imgLeft = screenWidth / 2 + actualOffsetX - imgW / 2;
                final imgTop = screenHeight / 2 + actualOffsetY - imgH / 2;

                final matrix = Matrix4.identity()
                  ..translate(offsetX, offsetY)
                  ..scale(scale);
                final screenPath = region.path.transform(matrix.storage);

                final fadeAnimation = _fadeAnimations[region.id];

                // Positioned를 FadeTransition 바깥으로
                return Positioned(
                  left: screenLeft,
                  top: screenTop,
                  width: screenWidth,
                  height: screenHeight,
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: fadeAnimation ??
                          const AlwaysStoppedAnimation(1.0), // null이면 불투명
                      child: ClipPath(
                        clipper: _PathClipper(screenPath, screenLeft, screenTop),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              left: imgLeft,
                              top: imgTop,
                              width: imgW,
                              height: imgH,
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.contain, // cover → contain
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _KoreaMapPainter extends CustomPainter {
  final List<RegionPath> regions;
  final Set<String> visitedIds;
  final Map<String, String> photoUrls;
  final double scale;
  final double offsetX;
  final double offsetY;
  final String? tappedRegionId;
  final double tapScale;
  final Map<String, Animation<double>> fadeAnimations;
  final Map<String, TextPainter> _textPainterCache = {};

  _KoreaMapPainter({
    required this.regions,
    required this.visitedIds,
    required this.photoUrls,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    this.tappedRegionId,
    this.tapScale = 1.0,
    required this.fadeAnimations,
  });

  TextPainter _getTextPainter(String text, double fontSize) {
    final key = '$text-$fontSize';
    return _textPainterCache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.black87,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      return tp;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    for (final region in regions) {
      final isVisited = visitedIds.contains(region.id);
      final hasPhoto = photoUrls.containsKey(region.id);
      final isTapped = region.id == tappedRegionId;

      // 탭된 지역 확대 애니메이션
      if (isTapped) {
        final bounds = region.path.getBounds();
        final center = bounds.center;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(tapScale);
        canvas.translate(-center.dx, -center.dy);
      }

      // 페이드인 효과
      final fadeAnim = fadeAnimations[region.id];
      final opacity = isVisited
          ? (fadeAnim != null ? fadeAnim.value : 1.0)
          : 1.0;

      // 탭된 지역 강조 색상
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isTapped
            ? const Color(0xFF1A5CB5).withOpacity(opacity) // 탭 시 더 진한 파란색
            : (isVisited && hasPhoto
            ? const Color(0xFF4A90D9).withOpacity(0.3)
            : isVisited
            ? const Color(0xFF4A90D9)
            : const Color(0xFFD9D9D9))
            .withOpacity(opacity);
      canvas.drawPath(region.path, fillPaint);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 0.5;
      canvas.drawPath(region.path, strokePaint);

      if (isTapped) canvas.restore();

      // 텍스트 표시
      if (!hasPhoto) {
        final koreanName = _svgIdToKorean[region.id];
        if (koreanName != null) {
          final bounds = region.path.getBounds();
          if (bounds.width > 8 && bounds.height > 8 || region.id == 'dokdo') {
            final fontSize = bounds.width < 15 ? 4.0 : 6.0;

            const offsetAdjustments = <String, Offset>{
              'taebaek': Offset(0, 6), // 아래로 이동
              'gimpo': Offset(-3, 0), // 왼쪽으로 이동
              'yeoju': Offset(3, 0), // 오른쪽으로 이동
              'yesan': Offset(3, 0),
              'gyeryong': Offset(-2, 0),
              'pohang': Offset(0, -3), // 위로 이동
              'cheongdo': Offset(0, 6),
              'wanju': Offset(3, -9),
              'cheorwon': Offset(-6, 0),
              'goseong': Offset(-6, 0),
              '고성군': Offset(-6, 0),
              'uljin': Offset(0, -6),
              'muan': Offset(6, 0),
              'sinan': Offset(0, -3),
              'haenam': Offset(0, -9),
              'gangjin': Offset(0, -9),
              'jangheung': Offset(0, -9),
              'sunchang': Offset(3, 0),
              'boryeong': Offset(3, 0),
              'seosan': Offset(0, 6),
              'eumseong': Offset(-6, 3),
              'wonju': Offset(-6, 0),
              'jecheon': Offset(3, 0),
              'danyang': Offset(-6, 0),
              'hoengseong': Offset(3, -3),
              'yeosu': Offset(0, -3),
              'namhae': Offset(0, 3),
              'goryeong': Offset(-3, 0),
              'okcheon': Offset(-6, 0),
              'seocheon': Offset(3, 0),
              'gunsan': Offset(3, 0),
              'uijeongbu': Offset(-1, -1),
              'icheon': Offset(-2, -1),
              'taean': Offset(0, -12)
            };

            const fontSizeAdjustments = <String, double>{
              'jeungpyeong': 3.0,
              'gyeryong': 3.0,
              'uiwang': 3.0,
              'gunpo': 3.0,
              'gwangmyeong': 3.0,
              'hanam': 5.0,
              'guri': 3.0,
              'uijeongbu': 4.0,
              'dongducheon': 4.0
            };

            final adjustment = offsetAdjustments[region.id] ?? Offset.zero;
            final adjustedFontSize = fontSizeAdjustments[region.id] ?? fontSize;
            final tp = _getTextPainter(koreanName, adjustedFontSize);

            tp.paint(
              canvas,
              Offset(
                bounds.center.dx - tp.width / 2 + adjustment.dx,
                bounds.center.dy - tp.height / 2 + adjustment.dy,
              ),
            );
          }
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_KoreaMapPainter oldDelegate) =>
      oldDelegate.visitedIds != visitedIds ||
          oldDelegate.photoUrls != photoUrls ||
          oldDelegate.tappedRegionId != tappedRegionId ||
          oldDelegate.tapScale != tapScale;
}

// SVG path → Flutter Path 변환기
class _SvgPathConverter extends PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x, double y) =>
      path.cubicTo(x1, y1, x2, y2, x, y);

  @override
  void close() => path.close();
}

// korea_map_widget.dart 맨 아래

class _PathClipper extends CustomClipper<Path> {
  final Path path;
  final double offsetX;
  final double offsetY;

  _PathClipper(this.path, this.offsetX, this.offsetY);

  @override
  Path getClip(Size size) {
    final matrix = Matrix4.identity()..translate(-offsetX, -offsetY);
    return path.transform(matrix.storage);
  }

  @override
  bool shouldReclip(_PathClipper old) => false;
}

const Map<String, String> _svgIdToKorean = {
  'seoul': '서울', 'busan': '부산', 'daegu': '대구',
  'incheon': '인천', 'gwangju': '광주', 'daejeon': '대전',
  'ulsan': '울산', 'sejong': '세종', 'gyeonggi': '광주',
  'suwon': '수원', 'goyang': '고양', 'yongin': '용인',
  'seongnam': '성남', 'bucheon': '부천', 'ansan': '안산',
  'anyang': '안양', 'namyangju': '남양주', 'hwaseong': '화성',
  'pyeongtaek': '평택', 'uijeongbu': '의정부', 'paju': '파주',
  'siheung': '시흥', 'gimpo': '김포', 'gwangmyeong': '광명',
  'gapyeong': '가평', 'yangpyeong': '양평', 'icheon': '이천',
  'yeoju': '여주', 'anseong': '안성', 'osan': '오산',
  'hanam': '하남', 'guri': '구리', 'uiwang': '의왕',
  'gunpo': '군포', 'gwacheon': '과천', 'dongducheon': '동두천',
  'yangju': '양주', 'pocheon': '포천', 'yeoncheon': '연천',
  'ganghwa': '강화', 'chuncheon': '춘천', 'wonju': '원주',
  'gangneung': '강릉', 'donghae': '동해', 'taebaek': '태백',
  'sokcho': '속초', 'samcheok': '삼척', 'hongcheon': '홍천',
  'hoengseong': '횡성', 'yeongwol': '영월', 'pyeongchang': '평창',
  'Jeongseon': '정선', 'cheorwon': '철원', 'hwacheon': '화천',
  'yanggu': '양구', 'inje': '인제', 'yangyang': '양양',
  '고성군': '고성', 'cheonan': '천안', 'gongju': '공주',
  'asan': '아산', 'seosan': '서산', 'nonsan': '논산',
  'gyeryong': '계룡', 'dangjin': '당진', 'geumsan': '금산',
  'buyeo': '부여', 'seocheon': '서천', 'cheongyang': '청양',
  'hongseong': '홍성', 'yesan': '예산', 'taean': '태안',
  'cheongju': '청주', 'chungju': '충주', 'jecheon': '제천',
  'boeun': '보은', 'okcheon': '옥천', 'yeongdong': '영동',
  'jeungpyeong': '증평', 'jincheon': '진천', 'goesan': '괴산',
  'eumseong': '음성', 'danyang': '단양', 'jeonju': '전주',
  'gunsan': '군산', 'iksan': '익산', 'jeongeup': '정읍',
  'namwon': '남원', 'gimje': '김제', 'wanju': '완주',
  'jinan': '진안', 'muju': '무주', 'jangsu': '장수',
  'imsil': '임실', 'sunchang': '순창', 'gochang': '고창',
  'buan': '부안', 'mokpo': '목포',
  'yeosu': '여수', 'suncheon': '순천', 'naju': '나주',
  'gwangyang': '광양', 'damyang': '담양', 'gokseong': '곡성',
  'gurye': '구례', 'hwasun': '화순', 'jangheung': '장흥',
  'gangjin': '강진', 'haenam': '해남', 'yeongam': '영암',
  'muan': '무안', 'hampyeong': '함평', 'yeonggwang': '영광',
  'jangseong': '장성', 'wando': '완도', 'jindo': '진도',
  'sinan': '신안', 'boseong': '보성', 'goheung': '고흥',
  'jeju': '제주', 'seogwipo': '서귀포',
  'pohang': '포항', 'gyeongju': '경주',
  'gumi': '구미', 'andong': '안동', 'gimcheon': '김천',
  'mungyeong': '문경', 'sangju': '상주', 'yeongju': '영주',
  'yeongcheon': '영천', 'gyeongsan': '경산', 'chilgok': '칠곡',
  'seongju': '성주', 'goryeong': '고령', 'uiseong': '의성',
  'cheongsong': '청송', 'yeongyang': '영양', 'yeongdeok': '영덕',
  'cheongdo': '청도', 'gunwi': '군위', 'uljin': '울진',
  'ulleung': '울릉', 'bonghwa': '봉화', 'yecheon': '예천',
  'changwon': '창원', 'jinju': '진주',
  'tongyeong': '통영', 'sacheon': '사천', 'gimhae': '김해',
  'miryang': '밀양', 'geoje': '거제', 'yangsan': '양산',
  'changnyeong': '창녕', 'haman': '함안', 'uiryeong': '의령',
  'hapcheon': '합천', 'geochang': '거창', 'hamyang': '함양',
  'sancheong': '산청', 'hadong': '하동', 'namhae': '남해',
  'goseong': '고성', 'boryeong': '보령', 'dokdo': '독도'
};