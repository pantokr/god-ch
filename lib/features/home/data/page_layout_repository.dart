import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/page_layout.dart';

/// 교회 페이지 구성(어떤 페이지가 있고, 각 페이지에 어떤 구조·디자인이 쌓였는지)을 읽고 저장한다.
/// 읽기는 승인된 교인, 쓰기는 교역자·교회 운영자만 가능하다 (`firestore.rules`가 강제한다).
class PageLayoutRepository {
  PageLayoutRepository(FirebaseFirestore db) : _paths = FirestorePaths(db);

  final FirestorePaths _paths;

  CollectionReference<Map<String, dynamic>> _col(String churchId) =>
      _paths.church(churchId).collection('pages');

  /// 순서대로 정렬된 페이지들. 아직 저장된 구성이 없으면 기본 구성([PageConfig.defaults])이다.
  Stream<List<PageConfig>> pages(String churchId) =>
      _col(churchId).orderBy('order').snapshots().map((s) {
        if (s.docs.isEmpty) return PageConfig.defaults;
        return s.docs.map(PageConfig.fromDoc).toList();
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
      if (p.blocks.length > 20) {
        throw const AppException('한 페이지에는 구조를 20개까지 쌓을 수 있어요.');
      }
    }
    final batch = _paths.db.batch();
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      batch.set(_col(churchId).doc(p.id), {
        'title': p.title.trim(),
        'icon': p.icon,
        'order': i,
        'blocks': [for (final b in p.blocks) b.toMap()],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    for (final id in removedIds) {
      batch.delete(_col(churchId).doc(id));
    }
    await batch.commit();
  }
}
