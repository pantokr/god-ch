import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

/// 교인 문서를 읽어 사람 목록용 복사본(`people/{uid}`)을 맞춰 쓴다 ([PersonCard] 참고).
/// 교인 문서의 이름 · 사진 · 역할 · 상태 · 소속 · 생년월일이 바뀐 직후에 부른다.
/// 복사본은 부가 정보라서 쓰기에 실패해도 원래 동작은 실패로 만들지 않는다.
Future<void> mirrorPersonCard(
  FirestorePaths paths,
  String churchId,
  String uid,
) async {
  try {
    final snap = await paths.members(churchId).doc(uid).get();
    final d = snap.data();
    if (d == null) return;
    final born = DateTime.tryParse((d['birthDate'] as String? ?? '').trim());
    String two(int n) => n.toString().padLeft(2, '0');
    await paths.people(churchId).doc(uid).set({
      'uid': uid,
      'name': d['name'] as String? ?? '',
      'photoUrl': d['photoUrl'] as String? ?? '',
      'role': d['role'] as String? ?? 'member',
      'status': d['status'] as String? ?? 'pending',
      'affiliationIds': List<String>.from(
        d['affiliationIds'] as List? ?? const [],
      ),
      'birthMonthDay': born == null
          ? ''
          : '${two(born.month)}-${two(born.day)}',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // 사람 목록 복사본은 다음 변경 때 다시 맞춰진다.
  }
}
