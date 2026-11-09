import 'package:flutter/material.dart';

import '../../../core/layout/manage_list_row.dart';
import '../../../core/widgets/member_mark.dart';
import '../../../data/models/member.dart';
import '../../../data/models/person_card.dart';
import 'person_popup.dart';

/// 사람 한 줄: 사진 · 이름(앞에 직급 아이콘) · 오른쪽 버튼. 줄을 누르면 프로필 팝업이 뜬다.
/// 일반 화면의 사람 목록(모임 참여자 · 승인 대기 · 우리 소속)이 모두 이 줄을 쓴다.
class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.churchId,
    required this.uid,
    required this.card,
    this.badge,
    this.trailing = const [],
  });

  final String churchId;
  final String uid;

  /// 사람 정보 (아직 못 불러왔으면 null).
  final PersonCard? card;
  final String? badge;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final name = card?.name ?? '';
    return ManageListRow(
      onTap: () => showPersonPopup(
        context,
        churchId: churchId,
        uid: uid,
        name: name,
        photoUrl: card?.photoUrl ?? '',
      ),
      leading: ManageListRow.avatar(
        context,
        name.isEmpty ? '?' : name,
        imageUrl: card?.photoUrl ?? '',
      ),
      title: name.isEmpty ? '이름 없음' : name,
      titleMark: MemberMark(role: card?.role ?? Role.member),
      badge: badge,
      trailing: trailing,
    );
  }
}
