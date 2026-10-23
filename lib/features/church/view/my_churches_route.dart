import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church_request.dart';
import '../../../data/models/member.dart';
import '../view_model/my_churches_view_model.dart';
import 'my_churches_page.dart';

/// 주소 `/churches`: 내 교회 목록. 교회나 부서를 고르면 그 주소로 이동해
/// 브라우저 뒤로가기로 목록에 돌아올 수 있다.
/// 승인된 교회가 하나라도 있으면 목록을 거치지 않고 바로 그 교회의 메인으로 들어간다
/// ([showList]가 true일 때, 즉 "내 교회 목록"을 일부러 열었을 때는 제외).
class MyChurchesRoute extends StatelessWidget {
  const MyChurchesRoute({super.key, this.showList = false});

  final bool showList;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyChurchesViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MyChurchesViewModel(
          scope.churches,
          scope.churchRequests,
          scope.auth,
        );
      },
      builder: (context, vm) => StreamBuilder<List<Member>>(
        stream: vm.memberships,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(
              body: Center(child: Text('불러오지 못했습니다\n${snap.error}')),
            );
          }
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final memberships = snap.data!;
          final approved = memberships.where((m) => m.isApproved).toList();
          if (!showList && approved.isNotEmpty) {
            return _EnterChurch(
              approved: approved,
              lastChurchId: vm.lastChurchId,
            );
          }
          return StreamBuilder<List<ChurchRequest>>(
            stream: vm.myRequests,
            builder: (context, requests) => MyChurchesPage(
              approved: approved,
              others: memberships.where((m) => !m.isApproved).toList(),
              // 승인된 요청은 이미 내 교회로 보이므로 대기·거절만 보여준다.
              requests: (requests.data ?? const <ChurchRequest>[])
                  .where((r) => r.status != RequestStatus.approved)
                  .toList(),
              userName: vm.userName,
              userEmail: vm.userEmail,
              onSignOut: vm.signOut,
              // 부서 공간은 그 부서의 중보기도로, 교회 전체는 메인으로 들어간다.
              onOpen: (church, department) => context.go(
                department == null
                    ? Routes.home(church.churchId)
                    : Routes.section(
                        church.churchId,
                        ChurchSection.feed,
                        dept: department.id,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 마지막으로 들어간 교회(없으면 첫 교회)의 메인으로 보낸다.
class _EnterChurch extends StatefulWidget {
  const _EnterChurch({required this.approved, required this.lastChurchId});

  final List<Member> approved;
  final Future<String?> Function() lastChurchId;

  @override
  State<_EnterChurch> createState() => _EnterChurchState();
}

class _EnterChurchState extends State<_EnterChurch> {
  @override
  void initState() {
    super.initState();
    _enter();
  }

  Future<void> _enter() async {
    final last = await widget.lastChurchId();
    if (!mounted) return;
    final target =
        widget.approved.where((m) => m.churchId == last).firstOrNull ??
        widget.approved.first;
    context.go(Routes.home(target.churchId));
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
