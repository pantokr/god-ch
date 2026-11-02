import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;

import '../../../data/firestore_paths.dart';
import '../../../data/models/person_card.dart';

/// 교회 사람 목록 (이름 · 사진 · 역할 · 소속 · 생일). 승인된 교인이면 누구나 읽는다.
class PeopleRepository {
  PeopleRepository(FirebaseFirestore db) : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final Map<String, ValueNotifier<Map<String, String>>> _photos = {};

  /// 승인된 교인들. 앱 운영자 계정은 교인이 아니므로 뺀다.
  Stream<List<PersonCard>> people(String churchId) => _paths
      .people(churchId)
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            if (d.id != 'app-operator-admin') PersonCard.fromDoc(d),
        ],
      );

  /// 교회 교인들의 프로필 사진 주소 (uid → 주소). 교회마다 한 번만 구독해 두고 모든 아바타가 같이 쓴다.
  /// 글 · 모임 문서에는 쓴 사람의 이름만 있어서, 사진은 여기서 찾아 붙인다. 사진이 없는 사람은 빠진다.
  ValueListenable<Map<String, String>> photos(String churchId) {
    final cached = _photos[churchId];
    if (cached != null) return cached;
    final notifier = ValueNotifier<Map<String, String>>(const {});
    _photos[churchId] = notifier;
    people(churchId).listen(
      (list) => notifier.value = {
        for (final p in list)
          if (p.photoUrl.isNotEmpty) p.id: p.photoUrl,
      },
      onError: (_) {},
    );
    return notifier;
  }
}
