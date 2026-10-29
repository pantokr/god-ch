import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'affiliation.dart';
import 'member.dart';

/// 소속마다 쓸 수 있는 기능: 기도제목과 성경. 교역자가 소속별로 켜고 끈다.
/// 설정한 적이 없는 기능은 모든 소속이 쓸 수 있다.
/// `churches/{id}/settings/features`에 저장되고, `firestore.rules`가 같은 기준으로 막는다.
enum PageFeature {
  prayer('기도'),
  word('성경');

  const PageFeature(this.label);

  final String label;
}

class ChurchFeatures {
  const ChurchFeatures({this.prayerAffiliations, this.wordAffiliations});

  /// 기도 탭을 쓸 수 있는 소속 ID들. null이면 설정한 적 없음(모두 허용).
  final Set<String>? prayerAffiliations;

  /// 말씀 탭을 쓸 수 있는 소속 ID들. null이면 설정한 적 없음(모두 허용).
  final Set<String>? wordAffiliations;

  static const unconfigured = ChurchFeatures();

  factory ChurchFeatures.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data();
    if (d == null) return unconfigured;
    Set<String>? ids(String key) =>
        d[key] is List ? Set<String>.from(d[key] as List) : null;
    return ChurchFeatures(
      prayerAffiliations: ids('prayerAffiliations'),
      wordAffiliations: ids('wordAffiliations'),
    );
  }

  Map<String, Object> toMap() => {
    if (prayerAffiliations != null)
      'prayerAffiliations': [...prayerAffiliations!],
    if (wordAffiliations != null) 'wordAffiliations': [...wordAffiliations!],
  };

  Set<String>? _of(PageFeature feature) => switch (feature) {
    PageFeature.prayer => prayerAffiliations,
    PageFeature.word => wordAffiliations,
  };

  /// [affiliationId] 소속이 [feature]를 쓸 수 있는가.
  bool allows(PageFeature feature, String affiliationId) =>
      _of(feature)?.contains(affiliationId) ?? true;

  /// [affiliationId] 소속의 [feature]를 [on]으로 바꾼 설정. 아직 설정한 적 없는 기능이면
  /// 다른 소속은 지금처럼 허용된 채로 두고 이 소속만 바꾼다 ([allAffiliationIds]가 기준).
  ChurchFeatures toggled(
    PageFeature feature,
    String affiliationId,
    bool on,
    Iterable<String> allAffiliationIds,
  ) {
    final next = {...(_of(feature) ?? allAffiliationIds)};
    on ? next.add(affiliationId) : next.remove(affiliationId);
    return switch (feature) {
      PageFeature.prayer => ChurchFeatures(
        prayerAffiliations: next,
        wordAffiliations: wordAffiliations,
      ),
      PageFeature.word => ChurchFeatures(
        prayerAffiliations: prayerAffiliations,
        wordAffiliations: next,
      ),
    };
  }

  /// 내가 [feature]를 쓸 수 있는지와, 쓸 수 있는 소속 선택지. 기능이 없는 페이지(null)는 막히지 않는다.
  /// - 교역자 · 운영자는 막히지 않고, 자기 소속이 선택지다.
  /// - 소속이 없으면 막히지 않는다 (교회 전체).
  /// - 소속이 있는데 하나도 허용되지 않았으면 막힌다.
  TabAccess accessFor(PageFeature? feature, Member me, List<Affiliation> all) {
    if (feature == null) return const TabAccess();
    // 교역자 · 운영자는 막히지 않지만, 보고 쓰는 소속은 자기 소속 중에서 고른다 ("전체"는 없다).
    if (me.isStaff) {
      return TabAccess(
        options: [
          for (final d in all)
            if (me.affiliationIds.contains(d.id)) d,
        ],
      );
    }
    final ids = me.affiliationIds;
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

  /// 소속 어디에서도 허용되지 않았다.
  final bool blocked;

  /// 탭에서 고를 수 있는 소속들. 비어 있으면 교회 전체로 본다.
  final List<Affiliation> options;
}
