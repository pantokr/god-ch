import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/firestore_paths.dart';
import '../../../data/models/member.dart';

/// 교회 운영자(admin)는 자동으로 모든 소속에 속한다: 아직 속하지 않은 소속을 소속에 더한다.
/// 이미 모두 속해 있으면 아무것도 쓰지 않는다 (몇 번을 불러도 같은 결과).
/// 소속을 만들 때, 교인을 운영자로 지정할 때, 소속 · 회원 관리 화면을 열 때 부른다.
Future<void> syncAdminAffiliations(
  FirestorePaths paths,
  String churchId,
) async {
  final affiliations = await paths.affiliations(churchId).get();
  if (affiliations.docs.isEmpty) return;
  final ids = [for (final d in affiliations.docs) d.id];
  final admins = await paths
      .members(churchId)
      .where('role', isEqualTo: Role.admin.name)
      .get();
  final batch = paths.db.batch();
  var writes = 0;
  for (final doc in admins.docs) {
    final m = Member.fromDoc(doc);
    if (!m.isApproved) continue;
    final missing = ids.where((id) => !m.affiliationIds.contains(id)).toList();
    if (missing.isEmpty) continue;
    batch.update(doc.reference, {
      'affiliationIds': FieldValue.arrayUnion(missing),
    });
    writes++;
  }
  if (writes > 0) await batch.commit();
}
