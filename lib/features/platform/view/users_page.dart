import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/user_profile.dart';
import '../../admin/view/member_detail_dialog.dart';
import '../view_model/users_view_model.dart';
import '../../../core/widgets/app_inputs.dart';

/// 앱 운영자 > 회원 관리: 가입한 전체 회원의 이름과 소속 교회 · 소속을 보고,
/// 수정을 누르면 상세 관리 창에서 고친다.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<UsersViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return UsersViewModel(scope.churchRegistry, scope.members);
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(title: '회원 관리'),
              AppSearchField(
                hint: '이름, 아이디, 이메일, 전화번호 검색',
                onChanged: vm.setQuery,
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가입한 회원 (${snap.data!.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Member>>(
                        stream: vm.memberships,
                        builder: (context, ms) =>
                            StreamBuilder<List<Affiliation>>(
                              stream: vm.affiliations,
                              builder: (context, affs) {
                                final all = ms.data ?? const <Member>[];
                                final list = affs.data ?? const <Affiliation>[];
                                return Card(
                                  child: Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < users.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const Divider(),
                                        _UserRow(
                                          vm: vm,
                                          user: users[i],
                                          memberships: [
                                            for (final m in all)
                                              if (m.id == users[i].uid) m,
                                          ],
                                          affiliations: list,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                      ),
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

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.vm,
    required this.user,
    required this.memberships,
    required this.affiliations,
  });

  final UsersViewModel vm;
  final UserProfile user;

  /// 이 회원이 속한 교회들.
  final List<Member> memberships;

  /// 모든 교회의 소속.
  final List<Affiliation> affiliations;

  List<Affiliation> _churchAffiliations(String churchId) => [
    for (final a in affiliations)
      if (a.churchId == churchId) a,
  ];

  void _edit(BuildContext context) {
    showAppDialog(
      context,
      child: MemberDetailDialog(
        vm: vm,
        title: user.name,
        name: user.name,
        phone: user.phone,
        address: user.address,
        birthDate: user.birthDate,
        photoUrl: user.photoUrl,
        onUploadPhoto: (fileName, bytes) =>
            vm.uploadPhoto(user.uid, fileName, bytes),
        showChurchNames: true,
        memberships: [
          for (final m in memberships)
            MembershipEditor(
              member: m,
              affiliations: _churchAffiliations(m.churchId),
              canRole: true,
              canStatus: true,
            ),
        ],
        onSave: (result) => vm.saveDetail(user, result),
      ),
    );
  }

  /// 소속 교회 이름들.
  String get _churches => memberships.map((m) => m.churchName).join(', ');

  /// 소속 이름들 (모든 교회의 것).
  String get _affiliationNames => [
    for (final m in memberships)
      for (final id in m.affiliationIds)
        for (final a in _churchAffiliations(m.churchId))
          if (a.id == id) a.name,
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    // 교회 관리·인원 관리와 같은 줄 모양: 이름(아이디) · 소속 교회 · 소속 · [관리].
    return ManageListRow(
      leading: ManageListRow.avatar(
        context,
        user.name,
        imageUrl: user.photoUrl,
      ),
      title: user.loginId == null
          ? user.name
          : '${user.name}  (${user.loginId})',
      line1: _churches,
      line2: _affiliationNames,
      onTap: () => _edit(context),
      trailing: [
        TextButton(onPressed: () => _edit(context), child: const Text('관리')),
      ],
    );
  }
}
