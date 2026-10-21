import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../view_model/member_admin_view_model.dart';
import 'invite_code_card.dart';
import 'member_tile.dart';

/// 초대 코드 관리와 교인 목록(가입 승인·비활성화·역할 지정).
class MemberAdminTab extends StatelessWidget {
  const MemberAdminTab({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MemberAdminViewModel>(
      create: (context) =>
          MemberAdminViewModel(AppScope.read(context).members, me),
      builder: (context, vm) => StreamBuilder<List<Member>>(
        stream: vm.members,
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text('불러오지 못했습니다\n${snap.error}'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = vm.sorted(snap.data!);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                InviteCodeCard(me: me),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < users.length; i++) ...[
                        if (i > 0) const Divider(),
                        MemberTile(member: users[i], vm: vm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
