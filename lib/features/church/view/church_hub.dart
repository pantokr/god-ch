import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church_request.dart';
import '../../../data/models/member.dart';
import '../../platform/view/platform_shell.dart';
import '../../shell/view/home_shell.dart';
import '../view_model/church_hub_view_model.dart';
import 'my_churches_page.dart';

/// 로그인 후 첫 화면.
/// - 앱 운영자: 교회에 소속되지 않고, 독립된 관리자 패널로 간다.
/// - 일반 회원: 교회에 들어가 있으면 교회 화면, 아니면 내 교회 목록.
class ChurchHub extends StatelessWidget {
  const ChurchHub({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchHubViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return ChurchHubViewModel(
          scope.churches,
          scope.churchRequests,
          scope.auth,
        );
      },
      builder: (context, vm) => StreamBuilder<bool>(
        stream: vm.isPlatformAdmin,
        builder: (context, admin) {
          if (!admin.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (admin.data!) {
            return PlatformShell(
              userName: vm.userName,
              userEmail: vm.userEmail,
              onSignOut: vm.signOut,
            );
          }
          return _MemberHub(vm: vm);
        },
      ),
    );
  }
}

/// 일반 회원: 내 교회 목록과 교회 화면.
class _MemberHub extends StatelessWidget {
  const _MemberHub({required this.vm});

  final ChurchHubViewModel vm;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Member>>(
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

        // 들어가 있는 교회에서 승인이 취소되면 메인 화면으로 돌아간다.
        final current = approved
            .where((m) => m.churchId == vm.openChurchId)
            .firstOrNull;
        if (current != null) {
          return HomeShell(
            // 교회나 부서가 바뀌면 화면 상태(탭 등)를 새로 시작한다.
            key: ValueKey('${current.churchId}/${vm.openDepartment?.id}'),
            me: current,
            department: vm.openDepartment,
            userName: vm.userName,
            userEmail: vm.userEmail,
            onSignOut: vm.signOut,
            onBack: vm.leave,
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
            onOpen: vm.open,
          ),
        );
      },
    );
  }
}
