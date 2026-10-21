import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../../shell/view/home_shell.dart';
import '../view_model/church_hub_view_model.dart';
import 'my_churches_page.dart';

/// 로그인 후 첫 화면. 교회에 들어가 있으면 교회 화면, 아니면 내 교회 목록을 보여준다.
class ChurchHub extends StatelessWidget {
  const ChurchHub({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchHubViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return ChurchHubViewModel(scope.churches, scope.auth);
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

          return MyChurchesPage(
            approved: approved,
            others: memberships.where((m) => !m.isApproved).toList(),
            userName: vm.userName,
            userEmail: vm.userEmail,
            onSignOut: vm.signOut,
            onOpen: vm.open,
          );
        },
      ),
    );
  }
}
