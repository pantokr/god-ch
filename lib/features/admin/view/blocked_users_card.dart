import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/blocked_user.dart';
import '../../../data/models/member.dart';
import '../view_model/blocked_users_view_model.dart';

/// 차단 목록. 차단된 계정은 이 교회에 입장을 신청할 수 없다.
/// 등록된 교인 · 입장 요청 회원은 회원 관리 창에서, 아이디는 여기서 직접 추가한다.
class BlockedUsersCard extends StatefulWidget {
  const BlockedUsersCard({super.key, required this.me});

  final Member me;

  @override
  State<BlockedUsersCard> createState() => _BlockedUsersCardState();
}

class _BlockedUsersCardState extends State<BlockedUsersCard> {
  final _id = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _add(BlockedUsersViewModel vm) async {
    final id = _id.text.trim();
    if (id.isEmpty) return;
    if (await vm.blockById(id)) _id.clear();
  }

  Future<void> _unblock(BlockedUsersViewModel vm, BlockedUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('차단 해제'),
        content: Text('${u.label}님의 차단을 풀까요?\n다시 초대 코드로 입장을 신청할 수 있게 돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (ok == true) await vm.unblock(u);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ViewModelBuilder<BlockedUsersViewModel>(
      create: (context) =>
          BlockedUsersViewModel(AppScope.read(context).members, widget.me),
      builder: (context, vm) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.block_outlined),
                  const SizedBox(width: 10),
                  Text('차단 목록', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '차단된 사람은 이 교회에 입장할 수 없고, 시도하면 접근할 수 없다는 안내가 나와요.',
                style: TextStyle(color: palette.muted),
              ),
              if (vm.canEdit) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _id,
                        autocorrect: false,
                        onSubmitted: (_) => _add(vm),
                        decoration: const InputDecoration(
                          hintText: '차단할 아이디를 입력하세요',
                          prefixIcon: Icon(Icons.person_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: AppField.height,
                      child: FilledButton(
                        onPressed: vm.busy ? null : () => _add(vm),
                        child: const Text('차단'),
                      ),
                    ),
                  ],
                ),
              ],
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              StreamBuilder<List<BlockedUser>>(
                stream: vm.blocked,
                builder: (context, snap) {
                  if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
                  final items = snap.data;
                  if (items == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '차단한 사람이 없어요.',
                        style: TextStyle(color: palette.muted),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.block),
                          title: Text(items[i].label),
                          subtitle:
                              items[i].name.isNotEmpty &&
                                  items[i].loginId.isNotEmpty
                              ? Text(items[i].loginId)
                              : null,
                          trailing: vm.canEdit
                              ? TextButton(
                                  onPressed: vm.busy
                                      ? null
                                      : () => _unblock(vm, items[i]),
                                  child: const Text('해제'),
                                )
                              : null,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
