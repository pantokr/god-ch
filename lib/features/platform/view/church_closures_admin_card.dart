import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_closure_request.dart';
import '../../church/view/church_requests_admin_card.dart'
    show RejectReasonForm;
import '../../church/view_model/church_closure_view_model.dart';

/// 앱 운영자 전용: 교회 폐쇄 요청을 확인하고 승인/거절한다. 승인해도 교회와 기록은 지우지 않는다.
class ChurchClosuresAdminCard extends StatelessWidget {
  const ChurchClosuresAdminCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchClosuresAdminViewModel>(
      create: (context) =>
          ChurchClosuresAdminViewModel(AppScope.read(context).churchClosures),
      builder: (context, vm) => StreamBuilder<List<ChurchClosureRequest>>(
        stream: vm.pending,
        builder: (context, snap) {
          final items = snap.data ?? const <ChurchClosureRequest>[];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(AppIcons.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '교회 폐쇄 요청 · ${items.length}건',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  if (vm.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      vm.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (snap.hasError)
                    Text('불러오지 못했습니다\n${snap.error}')
                  else if (items.isEmpty)
                    Text(
                      '처리할 폐쇄 요청이 없어요.',
                      style: TextStyle(color: context.palette.muted),
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 32),
                      _Row(request: items[i], vm: vm),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.request, required this.vm});

  final ChurchClosureRequest request;
  final ChurchClosuresAdminViewModel vm;

  Future<void> _approve(BuildContext context) async {
    final ok = await confirmChange(
      context,
      title: '${request.churchName} 교회를 폐쇄할까요?',
      body: '교인은 더 이상 이 교회를 쓸 수 없어요. 글과 기록은 지워지지 않고 보관돼요.',
      confirmLabel: '폐쇄',
    );
    if (ok) await vm.approve(request);
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showAppDialog<String>(
      context,
      maxWidth: 420,
      child: const RejectReasonForm(),
    );
    if (reason == null) return;
    await vm.reject(request, reason);
  }

  @override
  Widget build(BuildContext context) {
    final r = request;
    final muted = TextStyle(color: context.palette.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.churchName,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text('사유  ${r.reason}', style: muted),
        Text('요청자  ${r.requesterName} · ${fmtDate(r.createdAt)}', style: muted),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: vm.busy ? null : () => _approve(context),
                child: const Text('폐쇄 승인'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: vm.busy ? null : () => _reject(context),
                child: const Text('거절'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
