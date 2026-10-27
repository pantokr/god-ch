import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/app_exception.dart';
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

  /// 구성 전체를 저장한다. [pages]의 순서가 메뉴 순서가 되고, [removedIds]의 페이지는 지운다.
  Future<void> save(
    String churchId,
    List<PageConfig> pages, {
    List<String> removedIds = const [],
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
    final batch = _paths.db.batch();
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      batch.set(_col(churchId).doc(p.id), {
        'title': p.title.trim(),
        'icon': p.icon,
        'order': i,
        'group': p.group.id,
        if (p.layout != null) 'layout': p.layout!.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    // 지운 페이지는 문서를 남기고 deleted 표시만 한다 (저장된 적 없는 기본 페이지는 건너뛴다).
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
  }
}
