import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/repository/block_repository.dart';
import '../model/map_member_model.dart';
import '../provider/map_provider.dart';
import '../../user/provider/user_provider.dart';
import '../../../core/network/dio_provider.dart';
import 'package:dio/dio.dart';

// ReportRepository
class ReportRepository {
  final Dio _dio;
  ReportRepository(this._dio);

  Future<void> report({
    required int targetUserId,
    required String reason,
  }) async {
    await _dio.post('/reports', data: {
      'targetUserId': targetUserId,
      'reason': reason,
    });
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(dioProvider));
});

class MapMemberScreen extends ConsumerStatefulWidget {
  final int mapId;

  const MapMemberScreen({super.key, required this.mapId});

  @override
  ConsumerState<MapMemberScreen> createState() => _MapMemberScreenState();
}

class _MapMemberScreenState extends ConsumerState<MapMemberScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  dynamic _searchResult;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 멤버 목록 강제 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(mapMembersProvider(widget.mapId));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchResult = null;
    });
    try {
      final user = await ref.read(userRepositoryProvider)
          .searchUser(_searchController.text.trim());

      final myProfile = await ref.read(userRepositoryProvider).getMe();
      if (user.id == myProfile.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('본인은 초대할 수 없어요.')),
          );
        }
        setState(() => _isSearching = false);
        return;
      }

      setState(() => _searchResult = user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 닉네임의 유저를 찾을 수 없어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _inviteMember(int userId) async {
    try {
      await ref.read(mapRepositoryProvider).inviteMember(widget.mapId, userId);
      ref.invalidate(mapMembersProvider(widget.mapId));
      setState(() => _searchResult = null);
      _searchController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대했어요!')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('403') ||
            e.toString().contains('접근 권한')
            ? '차단한 유저는 초대할 수 없어요.'
            : '초대에 실패했어요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _removeMember(int userId) async {
    try {
      await ref.read(mapRepositoryProvider).removeMember(widget.mapId, userId);
      ref.invalidate(mapMembersProvider(widget.mapId));
      ref.invalidate(myMapsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('멤버 삭제에 실패했어요.')),
        );
      }
    }
  }

  void _showReportDialog(MapMemberModel member) {
    final reasons = [
      '스팸 또는 광고',
      '욕설 및 혐오 발언',
      '개인정보 침해',
      '부적절한 사진',
      '기타',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${member.nickname} 신고'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map((reason) => ListTile(
            title: Text(reason, style: const TextStyle(fontSize: 14)),
            dense: true,
            onTap: () async {
              Navigator.pop(context);
              await _submitReport(member.userId, reason);
            },
          ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(MapMemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('유저 차단'),
        content: Text('${member.nickname}님을 차단할까요?\n차단하면 서로 초대할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('차단'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(blockRepositoryProvider).block(member.userId);
      ref.invalidate(mapMembersProvider(widget.mapId)); // 추가
      ref.invalidate(myMapsProvider); // 추가
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단됐어요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('이미 차단')
            ? '이미 차단한 유저예요.'
            : '차단에 실패했어요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _submitReport(int targetUserId, String reason) async {
    try {
      await ref.read(reportRepositoryProvider).report(
        targetUserId: targetUserId,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수됐어요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('이미 신고')
            ? '이미 신고한 유저예요.'
            : '신고에 실패했어요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(mapMembersProvider(widget.mapId));
    final myProfileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('멤버 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 유저 검색
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '닉네임으로 검색',
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,
                  child: _isSearching
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 검색 결과
            if (_searchResult != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _searchResult.profileImageUrl != null
                        ? NetworkImage(_searchResult.profileImageUrl!)
                        : null,
                    child: _searchResult.profileImageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(_searchResult.nickname),
                  trailing: ElevatedButton(
                    onPressed: () => _inviteMember(_searchResult.id),
                    child: const Text('초대'),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const Text('현재 멤버', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // 멤버 목록
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('멤버를 불러오지 못했어요.')),
                data: (members) => myProfileAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const SizedBox(),
                  data: (myProfile) {
                    final isOwner = members
                        .any((m) => m.userId == myProfile.id && m.role == 'OWNER');

                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isMe = member.userId == myProfile.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member.profileImageUrl != null
                                ? NetworkImage(member.profileImageUrl!)
                                : null,
                            child: member.profileImageUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(member.nickname),
                          subtitle: Text(
                            member.role == 'OWNER' ? '소유자' : '멤버',
                          ),
                          trailing: isMe
                              ? null
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 신고 버튼
                              IconButton(
                                icon: const Icon(Icons.flag_outlined, color: Colors.grey),
                                onPressed: () => _showReportDialog(member),
                              ),
                              // 차단 버튼
                              IconButton(
                                icon: const Icon(Icons.block, color: Colors.orange),
                                onPressed: () => _blockUser(member),
                              ),
                              // 소유자만 멤버 삭제 가능
                              if (isOwner && member.role != 'OWNER')
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _removeMember(member.userId),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}