import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/theme.dart';
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ThumbnailAvatar(
              name: person?.name ?? name,
              url: person?.photoUrl.isNotEmpty == true
                  ? person!.photoUrl
                  : photoUrl,
              radius: 44,
            ),
            const SizedBox(height: 14),
            Text(
              person?.name ?? name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (person != null) ...[
              const SizedBox(height: 4),
              Text(
                person.positionName.isNotEmpty
                    ? person.positionName
                    : switch (person.role) {
                        Role.admin => '교회 운영자',
                        Role.staff => '교역자',
                        Role.member => '교인',
                      },
                style: TextStyle(color: palette.muted, fontSize: 13.5),
              ),
            ],
            const SizedBox(height: 14),
            if (!snap.hasData)
              const SizedBox(height: 28)
            else if (names.isEmpty)
              Text(
                Affiliation.unassignedName,
                style: TextStyle(color: palette.muted, fontSize: 13.5),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final n in names)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.ink.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(n, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
