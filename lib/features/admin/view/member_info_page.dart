import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/member_mark.dart';
import '../../../core/widgets/role_chips.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../data/models/member.dart';
import '../../../data/models/position.dart';
import '../../../data/models/user_profile.dart';

/// 회원 상세 페이지로 이동한다 (목록의 "관리"). 가운데에 회원의 모든 정보를 보이고,
/// [editor]가 있으면 그 아래 카드에 역할 · 소속 · 상태를 고치는 칸을 둔다.
Future<void> showMemberInfoPage(
  BuildContext context, {
  required Member member,
  String positionName = '',
  Position? position,
  List<String> affiliationNames = const [],
  Widget? editor,
  Widget? footer,
}) => _push(
  context,
  name: member.name,
  card: _InfoCard(
    name: member.name,
    photoUrl: member.photoUrl,
    positionName: positionName,
    role: member.role,
    position: position,
    affiliationNames: affiliationNames,
    rows: [
      ('아이디', member.loginId.isNotEmpty ? member.loginId : member.email, false),
      ('전화번호', member.phone, true),
      ('주소', member.address, true),
      ('생년월일', member.birthDate, false),
      ('상태', _InfoCard.status[member.status] ?? '', false),
      (
        '수락일',
        member.memberSince == null ? '' : fmtDate(member.memberSince),
        false,
      ),
      (
        // 입장 요청은 아직 가입 전이라 요청한 날이다.
        member.status == MemberStatus.pending ? '요청일' : '가입일',
        member.createdAt == null ? '' : fmtDateTime(member.createdAt),
        false,
      ),
    ],
  ),
  editor: editor,
  footer: footer,
);

/// 앱 운영자의 회원 상세 페이지 (회원 관리의 "관리"): 교회 안의 [showMemberInfoPage]와 같은 모양이다.
/// 한 회원이 여러 교회에 속할 수 있어, 역할 · 직급 대신 소속 교회와 소속을 보인다.
Future<void> showUserInfoPage(
  BuildContext context, {
  required UserProfile user,
  List<String> churchNames = const [],
  List<String> affiliationNames = const [],
  Widget? editor,
}) => _push(
  context,
  name: user.name,
  card: _InfoCard(
    name: user.name,
    photoUrl: user.photoUrl,
    positionName: '',
    role: Role.member,
    affiliationNames: affiliationNames,
    rows: [
      ('아이디', user.loginId ?? user.email, false),
      ('전화번호', user.phone, true),
      ('주소', user.address, true),
      ('생년월일', user.birthDate, false),
      ('소속 교회', churchNames.join(', '), false),
      ('가입일', user.createdAt == null ? '' : fmtDateTime(user.createdAt), false),
    ],
  ),
  editor: editor,
);

Future<void> _push(
  BuildContext context, {
  required String name,
  required Widget card,
  Widget? editor,
  Widget? footer,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  MaterialPageRoute(
    builder: (context) => SubPage(
      title: '',
      barTitle: '',
      fallbackLocation: '',
      onBack: () => Navigator.of(context).maybePop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card,
          // 관리 카드: 회원 관리는 역할 · 소속 · 상태를 고치는 칸, 소속 관리는 "소속에서 제외" 버튼이 같은 카드에 놓인다.
          if (editor != null || footer != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: editor ?? footer!,
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.name,
    required this.photoUrl,
    required this.positionName,
    required this.role,
    this.position,
    required this.affiliationNames,
    required this.rows,
  });

  final String name;
  final String photoUrl;
  final String positionName;
  final Role role;
  final Position? position;
  final List<String> affiliationNames;

  /// (이름, 값, 값이 없어도 "미제공"으로 보일지).
  final List<(String, String, bool)> rows;

  static const status = {
    MemberStatus.pending: '승인 대기',
    MemberStatus.approved: '승인됨',
    MemberStatus.disabled: '비활성',
    MemberStatus.removed: '추방됨',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget row(String label, String value, {bool required = false}) =>
        value.isEmpty && !required
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(label, style: TextStyle(color: palette.muted)),
                ),
                Expanded(
                  child: SelectableText(
                    value.isEmpty ? '미제공' : value,
                    style: value.isEmpty
                        ? TextStyle(color: palette.muted)
                        : null,
                  ),
                ),
              ],
            ),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ThumbnailAvatar(name: name, url: photoUrl, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MemberMark(role: role, position: position),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      if (positionName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            positionName,
                            style: TextStyle(color: palette.muted),
                          ),
                        ),
                      if (affiliationNames.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final a in affiliationNames)
                                AffiliationChip(a),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            for (final r in rows) row(r.$1, r.$2, required: r.$3),
          ],
        ),
      ),
    );
  }
}

/// 회원 상세 · 목록에서 직급 자리에 보이는 이름: 직급이 있으면 그 이름, 없으면 역할 (교인은 비어 있다).
String memberPositionLabel(Member m, {Position? position}) =>
    position?.name ??
    switch (m.role) {
      Role.admin => m.isAppOperator ? '' : '교회 운영자',
      Role.staff => '교역자',
      Role.member => '',
    };
