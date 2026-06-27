import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      imagePath: 'assets/onboarding/1_map_create.jpg',
      title: '나만의 여행 지도 만들기',
      description: '지역을 선택하고 제목을 입력해\n나만의 여행 지도를 만들어요.',
    ),
    _OnboardingData(
      imagePath: 'assets/onboarding/2_map_view.jpg',
      title: '한눈에 보는 여행 지도',
      description: '만들어진 지도의\n모든 지역을 한눈에 확인해요.',
    ),
    _OnboardingData(
      imagePath: 'assets/onboarding/3_photo_upload.jpg',
      title: '지역을 탭해서 사진 업로드',
      description: '사진으로 기록하고 싶은 지역을 선택하면\n사진을 추가해 여행을 기록할 수 있어요.',
    ),
    _OnboardingData(
      imagePath: 'assets/onboarding/4_photo_adjust.jpg',
      title: '지역 모양에 맞게 사진 위치 조정',
      description: '드래그로 위치를, 두 손가락으로\n사진 크기를 자유롭게 조정해요.',
    ),
    _OnboardingData(
      imagePath: 'assets/onboarding/5_photo_like.jpg',
      title: '마음에 드는 사진에 좋아요',
      description: '사진을 선택해 좋아요, 대표 사진 설정,\n위치 조정을 할 수 있어요.',
    ),
    _OnboardingData(
      imagePath: 'assets/onboarding/6_map_setting.jpg',
      title: '지도 표시 방식 선택',
      description: '대표 사진 또는 좋아요 사진 랜덤 출력 중\n원하는 방식으로 지도를 꾸며요.',
    ),
    _OnboardingData(
      imagePath: 'assets/onboarding/7_member.jpg',
      title: '연인, 친구와 지도 공유',
      description: '닉네임으로 친구를 검색하고 초대하면\n지도를 공유하고 함께 기록할 수 있어요.',
    ),
    _OnboardingData(
      imagePath: 'assets/onboarding/8_map_done.jpg',
      title: '완성된 지도 갤러리에 저장',
      description: '상단 다운로드 버튼을 눌러\n완성된 여행 지도를 갤러리에 저장해요.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 인디케이터 + 건너뛰기
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 5),
                        width: _currentPage == index ? 18 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // 페이지 뷰
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? '다음' : '시작하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Column(
      children: [
        // 스크린샷 - 전체 보이도록 contain 사용
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.grey[900],
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain, // cover → contain으로 전체 화면 표시
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ),

        // 설명 텍스트
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            children: [
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingData {
  final String imagePath;
  final String title;
  final String description;

  _OnboardingData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}