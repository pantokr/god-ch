import 'affiliation.dart';
import 'member.dart';

/// 소속을 고르는 화면(중보기도 · 성경)의 종류. 이름표에 쓴다.
enum PageFeature {
  prayer('중보기도'),
  word('성경');

  const PageFeature(this.label);

  final String label;
}

/// 탭을 쓸 수 있는지 판단한 결과.
class TabAccess {
  const TabAccess({
    this.blocked = false,
    this.unassigned = false,
    this.options = const [],
  });

  /// 내가 [feature]를 쓸 수 있는지와, 쓸 수 있는 소속 선택지. 기능이 없는 페이지(null)는 막히지 않는다.
  /// - 교역자 · 운영자는 막히지 않고, 자기 소속이 선택지다 ("전체"는 없다).
  /// - 소속이 없는 교인(미배정)은 아무 글도 볼 수 없다.
  /// - 그 밖의 교인은 속한 소속이 모두 선택지다.
  factory TabAccess.of(PageFeature? feature, Member me, List<Affiliation> all) {
    if (feature == null) return const TabAccess();
    final ids = me.affiliationIds;
    if (!me.isStaff && ids.isEmpty) return const TabAccess(unassigned: true);
    return TabAccess(
      options: [
        for (final d in all)
          if (ids.contains(d.id)) d,
      ].sortedByName(),
    );
  }

  /// 소속 어디에서도 허용되지 않았다.
  final bool blocked;

  /// 속한 소속이 하나도 없다 (미배정).
  final bool unassigned;

  /// 탭에서 고를 수 있는 소속들. 비어 있으면 교회 전체로 본다.
  final List<Affiliation> options;
}
