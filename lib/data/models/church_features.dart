import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'department.dart';
import 'member.dart';
import 'page_layout.dart';

/// 기도 요청 · 말씀 묵상 페이지(어느 자리에 있든)를 부서마다 쓸 수 있는지. 교역자가 부서별로 켜고 끈다.
/// 설정한 적이 없는 탭(null)은 모든 부서가 쓸 수 있다.
/// `churches/{id}/settings/features`에 저장되고, `firestore.rules`가 같은 기준으로 막는다.
/// 부서별로 켜고 끌 수 있는 기능. 페이지가 어느 자리에 있는지가 아니라 구조(기도 요청 · 말씀 묵상)를 따른다.
enum PageFeature {
  prayer('기도'),
  word('말씀');

  const PageFeature(this.label);

  final String label;

  /// 이 구조의 페이지가 따르는 기능. 해당 없으면 null.
  static PageFeature? of(BlockType? type) => switch (type) {
    BlockType.prayer => prayer,
    BlockType.devotion => word,
    _ => null,
  };
}

class ChurchFeatures {
  const ChurchFeatures({this.prayerDepartments, this.wordDepartments});

  /// 기도 탭을 쓸 수 있는 부서 ID들. null이면 설정한 적 없음(모두 허용).
  final Set<String>? prayerDepartments;

  /// 말씀 탭을 쓸 수 있는 부서 ID들. null이면 설정한 적 없음(모두 허용).
  final Set<String>? wordDepartments;

  static const unconfigured = ChurchFeatures();

  factory ChurchFeatures.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data();
    if (d == null) return unconfigured;
    Set<String>? ids(String key) =>
        d[key] is List ? Set<String>.from(d[key] as List) : null;
    return ChurchFeatures(
      prayerDepartments: ids('prayerDepartments'),
      wordDepartments: ids('wordDepartments'),
    );
  }

  Map<String, Object> toMap() => {
    if (prayerDepartments != null) 'prayerDepartments': [...prayerDepartments!],
    if (wordDepartments != null) 'wordDepartments': [...wordDepartments!],
  };

  Set<String>? _of(PageFeature feature) => switch (feature) {
    PageFeature.prayer => prayerDepartments,
    PageFeature.word => wordDepartments,
  };

  /// [departmentId] 부서가 [feature]를 쓸 수 있는가.
  bool allows(PageFeature feature, String departmentId) =>
      _of(feature)?.contains(departmentId) ?? true;

  /// [departmentId] 부서의 [feature]를 [on]으로 바꾼 설정. 아직 설정한 적 없는 기능이면
  /// 다른 부서는 지금처럼 허용된 채로 두고 이 부서만 바꾼다 ([allDepartmentIds]가 기준).
  ChurchFeatures toggled(
    PageFeature feature,
    String departmentId,
    bool on,
    Iterable<String> allDepartmentIds,
  ) {
    final next = {...(_of(feature) ?? allDepartmentIds)};
    on ? next.add(departmentId) : next.remove(departmentId);
    return switch (feature) {
      PageFeature.prayer => ChurchFeatures(
        prayerDepartments: next,
        wordDepartments: wordDepartments,
      ),
      PageFeature.word => ChurchFeatures(
        prayerDepartments: prayerDepartments,
        wordDepartments: next,
      ),
    };
  }

  /// 내가 [feature]를 쓸 수 있는지와, 쓸 수 있는 부서 선택지. 기능이 없는 페이지(null)는 막히지 않는다.
  /// - 교역자 · 운영자는 막히지 않고, 자기 소속 부서가 선택지다.
  /// - 소속 부서가 없으면 막히지 않는다 (교회 전체).
  /// - 소속 부서가 있는데 하나도 허용되지 않았으면 막힌다.
  TabAccess accessFor(PageFeature? feature, Member me, List<Department> all) {
    if (feature == null) return const TabAccess();
    // 교역자 · 운영자는 막히지 않지만, 보고 쓰는 부서는 자기 소속 부서 중에서 고른다 ("전체"는 없다).
    if (me.isStaff) {
      return TabAccess(
        options: [
          for (final d in all)
            if (me.departmentIds.contains(d.id)) d,
        ],
      );
    }
    final ids = me.departmentIds;
    if (ids.isEmpty) return const TabAccess();
    final allowed = {
      for (final id in ids)
        if (allows(feature, id)) id,
    };
    return TabAccess(
      blocked: allowed.isEmpty,
      options: [
        for (final d in all)
          if (allowed.contains(d.id)) d,
      ],
    );
  }
}

/// 탭을 쓸 수 있는지 판단한 결과.
class TabAccess {
  const TabAccess({this.blocked = false, this.options = const []});

  /// 소속 부서 어디에서도 허용되지 않았다.
  final bool blocked;

  /// 탭에서 고를 수 있는 부서들. 비어 있으면 교회 전체로 본다.
  final List<Department> options;
}
