import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../view_model/member_gate_view_model.dart';

/// 주소의 교회에서 승인된 교인에게만 [builder]의 화면을 보여준다.
/// 소속이 아니거나 승인이 취소되면 내 교회 목록으로 돌려보낸다.
class MemberGate extends StatelessWidget {
  const MemberGate({super.key, required this.churchId, required this.builder});

  final String churchId;
  final Widget Function(BuildContext context, Member me) builder;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MemberGateViewModel>(
      create: (context) =>
          MemberGateViewModel(AppScope.read(context).churches, churchId),
      builder: (context, vm) => StreamBuilder<Member?>(
        stream: vm.member,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(
              body: Center(child: Text('불러오지 못했습니다\n${snap.error}')),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final me = snap.data;
          if (me == null || !me.isApproved) {
            // 빌드 중에는 이동할 수 없으므로 그린 뒤에 이동한다.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(Routes.churches);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return builder(context, me);
        },
      ),
    );
  }
}
