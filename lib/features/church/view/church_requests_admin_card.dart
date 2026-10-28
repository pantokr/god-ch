import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_request.dart';
import '../view_model/church_requests_admin_view_model.dart';

/// 앱 운영자 전용: 승인 대기 중인 교회 생성 요청을 확인하고 승인/거절한다.
class ChurchRequestsAdminCard extends StatelessWidget {
  const ChurchRequestsAdminCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchRequestsAdminViewModel>(
      create: (context) =>
          ChurchRequestsAdminViewModel(AppScope.read(context).churchRequests),
      builder: (context, vm) => StreamBuilder<List<ChurchRequest>>(
        stream: vm.pending,
        builder: (context, snap) {
          final items = snap.data ?? const <ChurchRequest>[];
          return Card(
            child: Padding(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < kNarrow ? 16 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 좁은 화면에서 제목이 길어도 넘치지 않게 남는 폭 안에서 줄을 바꾼다.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(AppIcons.shieldCheck),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '교회 생성 요청 (운영자) · ${items.length}건',
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
                      '승인 대기 중인 요청이 없어요.',
                      style: TextStyle(color: context.palette.muted),
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 32),
                      _RequestRow(request: items[i], vm: vm),
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

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.vm});

  final ChurchRequest request;
  final ChurchRequestsAdminViewModel vm;

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
          r.name,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text('전화  ${r.phone}', style: muted),
        Text('주소  ${r.address}', style: muted),
        Text('요청자  ${r.requesterName} · ${fmtDate(r.createdAt)}', style: muted),
        const SizedBox(height: 12),
        // 좁은 화면에서는 두 버튼이 한 줄을 반씩 나눠 쓴다.
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: vm.busy ? null : () => vm.approve(r),
                child: const Text('승인'),
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

/// 거절 사유 입력. 입력한 사유를 돌려주고, 취소하면 null.
class RejectReasonForm extends StatefulWidget {
  const RejectReasonForm({super.key});

  @override
  State<RejectReasonForm> createState() => RejectReasonFormState();
}

class RejectReasonFormState extends State<RejectReasonForm> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('요청을 거절할까요?', style: Theme.of(context).textTheme.titleLarge),
        AppField.spacer,
        TextField(
          controller: _reason,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(labelText: '거절 사유 (요청자에게 보여요)'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _reason.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _reason.text.trim()),
              child: const Text('거절'),
            ),
          ],
        ),
      ],
    );
  }
}
