import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/member_mark.dart';
import '../../../core/widgets/role_chips.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart' show Role;
import '../../../data/models/person_card.dart';

/// 프로필 이미지나 이름을 눌렀을 때 [showPersonPopup]을 여는 감싸개.
/// [uid]가 비어 있으면(예전 글처럼 쓴 사람을 모를 때) 눌러도 아무 일도 없다.
class PersonTap extends StatelessWidget {
  const PersonTap({
    super.key,
    required this.churchId,
    required this.uid,
    required this.name,
    required this.child,
    this.photoUrl = '',
  });

  final String churchId;
  final String uid;
  final String name;

  /// 알고 있는 프로필 사진 주소 (사람 목록에서 못 찾을 때의 대비).
  final String photoUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPersonPopup(
        context,
        churchId: churchId,
        uid: uid,
        name: name,
        photoUrl: photoUrl,
      ),
      child: child,
    );
  }
}

/// 사람 한 명의 팝업: 썸네일, 이름, 속한 소속 전부.
Future<void> showPersonPopup(
  BuildContext context, {
  required String churchId,
  required String uid,
  required String name,
  String photoUrl = '',
}) => showAppDialog<void>(
  context,
  maxWidth: 360,
  child: _PersonPopup(
    churchId: churchId,
    uid: uid,
    name: name,
    photoUrl: photoUrl,
  ),
);

class _PersonPopup extends StatelessWidget {
  const _PersonPopup({
    required this.churchId,
    required this.uid,
    required this.name,
    required this.photoUrl,
  });

  final String churchId;
  final String uid;
  final String name;
  final String photoUrl;

  Future<(PersonCard?, List<Affiliation>)> _load(BuildContext context) async {
    final scope = AppScope.read(context);
    final person = await scope.people.person(churchId, uid);
    final affs = await scope.affiliations.affiliations(churchId).first;
    return (person, affs);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FutureBuilder<(PersonCard?, List<Affiliation>)>(
      future: _load(context),
      builder: (context, snap) {
        final person = snap.data?.$1;
        final all = snap.data?.$2 ?? const <Affiliation>[];
        final names = [
          for (final id in person?.affiliationIds ?? const <String>[])
            ?all.where((a) => a.id == id).firstOrNull?.name,
        ];
        final role = switch (person?.role) {
          Role.admin => '교회 운영자',
          Role.staff => '교역자',
          _ => '교인',
        };
        final birth = person?.birthMonthDay ?? '';
        final birthText = birth.length == 5
            ? '${person!.birthMonth}월 ${int.tryParse(birth.substring(3))}일'
            : '';
        Widget info(String label, Widget value) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  label,
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ),
              Expanded(child: value),
            ],
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 윗부분: 옅은 색 띠 위에 사진이 반쯤 걸쳐 놓인다.
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    gradient: LinearGradient(
                      colors: [
                        palette.brand.withValues(alpha: 0.22),
                        palette.accent.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 4),
                    ),
                    child: ThumbnailAvatar(
                      name: person?.name ?? name,
                      url: person?.photoUrl.isNotEmpty == true
                          ? person!.photoUrl
                          : photoUrl,
                      radius: 40,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (person != null) ...[
                  MemberMark(role: person.role, size: 20),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    person?.name ?? name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            if (person != null) ...[
              const SizedBox(height: 4),
              Text(
                person.positionName.isNotEmpty ? person.positionName : role,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 13.5),
              ),
            ],
            const SizedBox(height: 18),
            Divider(height: 1, color: context.cardEdge),
            if (!snap.hasData)
              const SizedBox(height: 56)
            else ...[
              info(
                '소속',
                names.isEmpty
                    ? Text(
                        Affiliation.unassignedName,
                        style: TextStyle(color: palette.muted, fontSize: 13.5),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [for (final n in names) AffiliationChip(n)],
                      ),
              ),
              if (birthText.isNotEmpty) info('생일', Text(birthText)),
            ],
            DialogActions(
              top: 20,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
