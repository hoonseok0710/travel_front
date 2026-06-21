import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/map_provider.dart';
import '../model/region_model.dart';

class MapCreateScreen extends ConsumerStatefulWidget {
  const MapCreateScreen({super.key});

  @override
  ConsumerState<MapCreateScreen> createState() => _MapCreateScreenState();
}

class _MapCreateScreenState extends ConsumerState<MapCreateScreen> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  RegionModel? _selectedRegion;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createMap() async {
    if (_isLoading) return; // 중복 탭 방지
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역을 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(mapRepositoryProvider).createMap(
        regionId: _selectedRegion!.id,
        title: _titleController.text.trim(),
      );
      ref.invalidate(myMapsProvider);
      if (mounted) context.pop();
    } on Exception catch (e) {
      if (mounted) {
        final message = e.toString().contains('409')
            ? '이미 같은 지역의 지도가 있어요.'
            : '지도 생성에 실패했어요. 잠시 후 다시 시도해주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(regionsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('지도 만들기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 지역 선택
              const Text('지역 선택',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              regionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Text('지역을 불러오지 못했어요.'),
                data: (regions) => DropdownButtonFormField<RegionModel>(
                  hint: const Text('지역을 선택해주세요'),
                  value: _selectedRegion,
                  items: regions
                      .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.name),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRegion = v),
                  validator: (v) => v == null ? '지역을 선택해주세요.' : null,
                ),
              ),
              const SizedBox(height: 24),

              // 지도 제목
              const Text('지도 제목',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 20,
                decoration: const InputDecoration(
                  hintText: '예) 2026 커플 여행',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '지도 제목을 입력해주세요.';
                  if (v.trim().length < 1) return '지도 제목을 입력해주세요.';
                  if (v.trim().length > 20) return '지도 제목은 20자 이하여야 해요.';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 생성 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _createMap,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('지도 만들기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}