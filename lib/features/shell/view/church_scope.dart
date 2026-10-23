import 'package:flutter/widgets.dart';

import '../../../data/models/department.dart';
import '../../../data/models/member.dart';

/// 교회 안의 화면들이 공유하는 정보: 내 교인 정보, 보고 있는 부서, 계정 정보.
/// 교회 틀([ChurchShell])이 만들고, 안쪽 페이지들이 [of]로 꺼내 쓴다.
class ChurchScope extends InheritedWidget {
  const ChurchScope({
    super.key,
    required this.me,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required super.child,
    this.department,
  });

  final Member me;

  /// 보고 있는 부서 전용 공간. 교회 전체를 보는 중이면 null.
  final Department? department;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;

  static ChurchScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChurchScope>();
    assert(scope != null, 'ChurchScope가 위젯 트리에 없습니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ChurchScope oldWidget) =>
      me != oldWidget.me ||
      department?.id != oldWidget.department?.id ||
      userName != oldWidget.userName;
}
