import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/page_layout.dart';

/// 교회 페이지 구성(어떤 페이지가 있고, 각 페이지에 어떤 레이아웃(구조·디자인)을 쓰는지)을 읽고 저장한다.
/// 읽기는 승인된 교인, 쓰기는 교역자·교회 운영자만 가능하다 (`firestore.rules`가 강제한다).
class PageLayoutRepository {
  PageLayoutRepository(FirebaseFirestore db) : _paths = FirestorePaths(db);

  final FirestorePaths _paths;

  CollectionReference<Map<String, dynamic>> _col(String churchId) =>
      _paths.church(churchId).collection('pages');

  /// 순서대로 정렬된 페이지들. 아직 저장된 구성이 없으면 기본 구성([PageConfig.defaults])이다.
  Stream<List<PageConfig>> pages(String churchId) =>
      _col(churchId).orderBy('order').snapshots().map((s) {
        // 지운 페이지(deleted)는 기록으로만 남고 메뉴에는 나오지 않는다.
        final live = s.docs.where((d) => d.data()['deleted'] != true).toList();
        if (live.isEmpty) return PageConfig.defaults;
        final pages = live.map(PageConfig.fromDoc).nonNulls.toList();
        return pages.isEmpty ? PageConfig.defaults : pages;
      });

  CollectionReference<Map<String, dynamic>> _revisions(String churchId) =>
      _paths.church(churchId).collection('pageRevisions');

  /// 지운 것이 아닌 페이지 문서들 중 가장 늦게 저장된 시각.
  static DateTime? _latestSaved(Iterable<QueryDocumentSnapshot<Json>> docs) {
    DateTime? v;
    for (final d in docs) {
      if (d.data()['deleted'] == true) continue;
      final t = toDate(d.data()['updatedAt']);
      if (t != null && (v == null || t.isAfter(v))) v = t;
    }
    return v;
  }

  /// 최근에 남긴 이전 구성들 (최신순 10개).
  Stream<List<PageRevision>> revisions(String churchId) =>
      _revisions(churchId)
          .orderBy('savedAt', descending: true)
          .limit(10)
          .snapshots()
          .map((s) => s.docs.map(PageRevision.fromDoc).toList());

  /// 구성 전체를 저장한다. [pages]의 순서가 메뉴 순서가 되고, [removedIds]의 페이지는 지운다.
  /// [expectedVersion]은 편집을 시작할 때 본 마지막 저장 시각이다. 그 사이에 다른 관리자가
  /// 저장했으면 덮어쓰지 않고 막는다. 저장 직전의 구성은 [revisions]에 남긴다.
  /// 저장한 뒤의 마지막 저장 시각을 돌려준다 (다음 저장의 [expectedVersion]으로 쓴다).
  Future<DateTime?> save(
    String churchId,
    List<PageConfig> pages, {
    List<String> removedIds = const [],
    DateTime? expectedVersion,
  }) async {
    if (pages.isEmpty) throw const AppException('페이지가 하나는 있어야 해요.');
    for (final p in pages) {
      if (p.title.trim().isEmpty) {
        throw const AppException('페이지 이름을 입력해 주세요.');
      }
      if (p.title.trim().length > 30) {
        throw const AppException('페이지 이름은 30자까지 쓸 수 있어요.');
      }
    }
    final slotError = PageConfig.slotError(pages);
    if (slotError != null) throw AppException(slotError);

    final before = await _col(churchId).get();
    final current = _latestSaved(before.docs);
    if (expectedVersion != null &&
        current != null &&
        current.isAfter(expectedVersion)) {
      throw const AppException('다른 관리자가 먼저 고쳤어요. 이 화면을 닫고 다시 열어 주세요.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final batch = _paths.db.batch();
    // 저장 직전의 구성을 남긴다 (되돌리기용).
    final live = before.docs.where((d) => d.data()['deleted'] != true).toList();
    if (live.isNotEmpty) {
      batch.set(_revisions(churchId).doc(), {
        'savedAt': FieldValue.serverTimestamp(),
        'savedBy': ?uid,
        'pages': [
          for (final d in live)
            {
              for (final e in d.data().entries)
                if (e.key != 'updatedAt') e.key: e.value,
              'id': d.id,
            },
        ],
      });
    }
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      batch.set(_col(churchId).doc(p.id), {
        'title': p.title.trim(),
        'icon': p.icon,
        'order': i,
        'group': p.group.id,
        'structures': [for (final b in p.blocks) b.toMap()],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    // 지운 페이지는 문서를 남기고 deleted 표시만 한다 (저장된 적 없는 기본 페이지는 건너뛴다).
    for (final id in removedIds) {
      final ref = _col(churchId).doc(id);
      if (!(await ref.get()).exists) continue;
      batch.update(ref, {
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': ?uid,
      });
    }
    await batch.commit();
    return _latestSaved((await _col(churchId).get()).docs);
  }
}
