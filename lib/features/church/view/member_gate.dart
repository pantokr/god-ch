import '../../../core/widgets/app_loader.dart';
import '../../../core/icons.dart';

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
      create: (context) => MemberGateViewModel(
        AppScope.read(context).churches,
        AppScope.read(context).churchRequests,
        AppScope.read(context).churchRegistry,
        churchId,
      ),
      builder: (context, vm) => StreamBuilder<Member?>(
        stream: vm.member,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(
              body: Center(child: Text('불러오지 못했습니다\n${snap.error}')),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: AppLoader()));
          }
          final me = snap.data;
          if (me == null || !me.isApproved) {
            // 빌드 중에는 이동할 수 없으므로 그린 뒤에 이동한다.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(Routes.churches);
            });
            return const Scaffold(body: Center(child: AppLoader()));
          }
          return StreamBuilder<bool>(
            stream: vm.closed,
            // 폐쇄된 교회도 앱 개발자는 열 수 있다.
            builder: (context, closed) =>
                closed.data == true && !me.isOperatorView
                ? const _ClosedChurch()
                : builder(context, me),
          );
        },
      ),
    );
  }
}

/// 폐쇄된 교회: 교인은 더 이상 들어갈 수 없다 (기록은 보관된다).
class _ClosedChurch extends StatelessWidget {
  const _ClosedChurch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.lock, size: 40),
              const SizedBox(height: 16),
              Text('폐쇄된 교회예요', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('이 교회는 더 이상 사용할 수 없어요.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(Routes.churchList),
                child: const Text('내 교회 목록'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
