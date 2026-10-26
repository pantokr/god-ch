import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/card_grid.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../view_model/platform_dashboard_view_model.dart';
import 'bible_upload_card.dart';

/// 앱 운영자 대시보드: 교회·요청·회원 현황.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PlatformDashboardViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return PlatformDashboardViewModel(
          scope.churchRegistry,
          scope.churchRequests,
        );
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(title: '대시보드', subtitle: '서비스 전체 현황이에요.'),
              CardGrid(
                minColumnWidth: 240,
                children: [
                  _StatCard(
                    icon: Icons.church_outlined,
                    label: '등록된 교회',
                    value: vm.churchCount,
                  ),
                  _StatCard(
                    icon: Icons.hourglass_top,
                    label: '승인 대기 중인 교회 생성 요청',
                    value: vm.pendingRequestCount,
                    highlightWhenPositive: true,
                    onTap: () => context.go(Routes.adminChurches),
                  ),
                  _StatCard(
                    icon: Icons.people_outline,
                    label: '가입한 회원',
                    value: vm.userCount,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const BibleUploadCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.highlightWhenPositive = false,
  });

  final IconData icon;
  final String label;
  final Stream<int> value;
  final VoidCallback? onTap;

  /// 0보다 크면 강조한다 (처리해야 할 일이 있다는 뜻).
  final bool highlightWhenPositive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<int>(
            stream: value,
            builder: (context, snap) {
              final count = snap.data;
              final highlight = highlightWhenPositive && (count ?? 0) > 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: highlight
                        ? context.palette.brand
                        : context.palette.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    count?.toString() ?? '-',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: highlight
                          ? context.palette.brand
                          : context.palette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: context.palette.muted)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
