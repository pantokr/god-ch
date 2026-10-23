import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/user_profile.dart';
import '../view_model/users_view_model.dart';

/// 앱 운영자 > 회원 관리: 가입한 전체 회원을 보고 검색한다 (읽기 전용).
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<UsersViewModel>(
      create: (context) =>
          UsersViewModel(AppScope.read(context).churchRegistry),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(
                title: '회원 관리',
                subtitle: '가입한 회원을 확인해요. 개인정보이므로 외부에 공유하지 마세요.',
              ),
              TextField(
                onChanged: vm.setQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '이름, 아이디, 이메일, 전화번호 검색',
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<UserProfile>>(
                stream: vm.users,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('불러오지 못했습니다\n${snap.error}');
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final users = snap.data!.where(vm.matches).toList();
                  if (users.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            '해당하는 회원이 없어요.',
                            style: TextStyle(color: context.palette.muted),
                          ),
                        ),
                      ),
                    );
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < users.length; i++) ...[
                          if (i > 0) const Divider(),
                          _UserRow(user: users[i]),
                        ],
                      ],
                    ),
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

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.palette.brand.withValues(alpha: 0.12),
        child: Text(
          user.name.isEmpty ? '?' : user.name.characters.first,
          style: TextStyle(
            color: context.palette.brand,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(user.name),
      subtitle: Text('${user.loginId ?? 'Google 계정'}\n${user.phone}'),
      isThreeLine: true,
      trailing: Text(
        fmtDate(user.createdAt),
        style: TextStyle(color: context.palette.muted, fontSize: 13),
      ),
    );
  }
}
