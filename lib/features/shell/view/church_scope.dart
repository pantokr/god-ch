import 'package:flutter/widgets.dart';

import '../../../data/models/member.dart';
import '../../home/view_model/affiliation_choice.dart';

/// 교회 안의 화면들이 공유하는 정보: 내 교인 정보, 계정 정보.
/// 교회 틀([ChurchShell])이 만들고, 안쪽 페이지들이 [of]로 꺼내 쓴다.
class ChurchScope extends InheritedWidget {
  const ChurchScope({
    super.key,
    required this.me,
    required this.userName,
    required this.onSignOut,
    required this.affiliationChoice,
    required super.child,
  });

  final Member me;
  final String userName;
  final VoidCallback onSignOut;

  /// 기도 · 성경 화면에서 지금 고른 소속.
  final AffiliationChoice affiliationChoice;

  static ChurchScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChurchScope>();
    assert(scope != null, 'ChurchScope가 위젯 트리에 없습니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ChurchScope oldWidget) =>
      me != oldWidget.me || userName != oldWidget.userName;
}
