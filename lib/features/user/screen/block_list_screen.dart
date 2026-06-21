import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/block_repository.dart';

class BlockListScreen extends ConsumerWidget {
  const BlockListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockListAsync = ref.watch(blockListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('차단 목록')),
      body: blockListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('불러오지 못했어요.')),
        data: (blocks) {
          if (blocks.isEmpty) {
            return const Center(
              child: Text('차단한 유저가 없어요.', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              final block = blocks[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: block.profileImageUrl != null
                      ? NetworkImage(block.profileImageUrl!)
                      : null,
                  child: block.profileImageUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(block.nickname),
                trailing: TextButton(
                  onPressed: () async {
                    await ref.read(blockRepositoryProvider).unblock(block.userId);
                    ref.invalidate(blockListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('차단이 해제됐어요.')),
                      );
                    }
                  },
                  child: const Text('차단 해제'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}