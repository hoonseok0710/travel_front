import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_app/features/user/repository/block_repository.dart';
import '../provider/user_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/provider/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('프로필을 불러오지 못했어요.')),
        data: (user) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 프로필 이미지
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickProfileImage(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 닉네임
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('닉네임'),
              subtitle: Text(user.nickname),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _showNicknameEditDialog(context, ref, user.nickname),
            ),
            const Divider(),

            // 이메일
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('이메일'),
              subtitle: Text(
                user.email.startsWith('kakao_') && user.email.endsWith('@kakao.com')
                    ? '카카오 로그인 유저입니다.'
                    : user.email,
              ),
            ),
            const Divider(),

            // 차단 목록
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('차단 목록'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.invalidate(blockListProvider);
                context.push('/block-list');
              },
            ),
            const Divider(),

            const SizedBox(height: 24),

            // 로그아웃
            OutlinedButton(
              onPressed: () async {
                await TokenStorage.clearTokens();
                ref.invalidate(isLoggedInProvider);
                if (context.mounted) context.go('/login');
              },
              child: const Text('로그아웃'),
            ),
            const SizedBox(height: 12),

            // 회원 탈퇴
            TextButton(
              onPressed: () => _showDeleteAccountDialog(context, ref),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('회원 탈퇴'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    try {
      await ref.read(userRepositoryProvider).updateProfileImage(file);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 변경에 실패했어요.')),
        );
      }
    }
  }

  void _showNicknameEditDialog(
      BuildContext context, WidgetRef ref, String currentNickname) {
    final controller = TextEditingController(text: currentNickname);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('닉네임 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(userRepositoryProvider)
                  .updateNickname(controller.text.trim());
              ref.invalidate(myProfileProvider);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('탈퇴하면 모든 데이터가 삭제돼요.\n정말 탈퇴할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(userRepositoryProvider).deleteAccount();
              await TokenStorage.clearTokens();
              ref.invalidate(isLoggedInProvider);
              if (context.mounted) context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }
}