import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_closure_request.dart';
import '../../../data/models/church_request.dart';
import '../../../data/models/member.dart';
import '../../church/view_model/church_closure_view_model.dart';

/// 교회 폐쇄 요청. 요청은 앱 운영자가 승인해야 효력이 생기고, 승인 전까지 교회는 그대로 운영된다.
/// 폐쇄되어도 교회의 글과 기록은 지우지 않고 보관한다.
class ChurchClosureCard extends StatelessWidget {
  const ChurchClosureCard({super.key, required this.me});

  final Member me;

  Future<void> _ask(BuildContext context, ChurchClosureViewModel vm) async {
    final reason = await showAppDialog<String>(
      context,
      maxWidth: 460,
      child: _ClosureForm(churchName: me.churchName),
    );
    if (reason == null) return;
    final ok = await vm.request(reason);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('폐쇄를 요청했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final error = Theme.of(context).colorScheme.error;
    return ViewModelBuilder<ChurchClosureViewModel>(
      create: (context) => ChurchClosureViewModel(
        AppScope.read(context).churchClosures,
        me.churchId,
        me.churchName,
      ),
      builder: (context, vm) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<ChurchClosureRequest?>(
            stream: vm.latest,
            builder: (context, snap) {
              final r = snap.data;
              final pending = r?.status == RequestStatus.pending;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.warning, color: error),
                      const SizedBox(width: 10),
                      Text(
                        '교회 폐쇄',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '폐쇄를 요청하면 앱 운영자가 확인한 뒤 처리해요. 폐쇄되면 교인이 더는 들어올 수 없고, 글과 기록은 보관돼요.',
                    style: TextStyle(color: palette.muted),
                  ),
                  if (pending) ...[
                    const SizedBox(height: 12),
                    Text(
                      '폐쇄 요청 처리를 기다리고 있어요 · ${fmtDate(r!.createdAt)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '사유  ${r.reason}',
                      style: TextStyle(color: palette.muted),
                    ),
                  ] else if (r?.status == RequestStatus.rejected) ...[
                    const SizedBox(height: 12),
                    Text(
                      '지난 폐쇄 요청이 거절되었어요'
                      '${(r!.rejectReason ?? '').isEmpty ? '' : ' · 사유: ${r.rejectReason}'}',
                      style: TextStyle(color: palette.muted),
                    ),
                  ],
                  if (vm.error != null) ...[
                    const SizedBox(height: 8),
                    Text(vm.error!, style: TextStyle(color: error)),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: vm.busy || pending
                        ? null
                        : () => _ask(context, vm),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: error,
                      side: BorderSide(color: error.withValues(alpha: 0.6)),
                    ),
                    icon: const Icon(AppIcons.prohibit, size: 18),
                    label: Text(pending ? '폐쇄 요청 중' : '폐쇄 요청'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 사유와 교회 이름을 입력받아 한 번 더 확인한다. 입력한 사유를 돌려주고, 취소하면 null.
class _ClosureForm extends StatefulWidget {
  const _ClosureForm({required this.churchName});

  final String churchName;

  @override
  State<_ClosureForm> createState() => _ClosureFormState();
}

class _ClosureFormState extends State<_ClosureForm> {
  final _reason = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready =>
      _reason.text.trim().isNotEmpty &&
      _confirm.text.trim() == widget.churchName.trim();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('교회 폐쇄를 요청할까요?', style: Theme.of(context).textTheme.titleLarge),
        AppField.spacer,
        TextField(
          controller: _reason,
          autofocus: true,
          // 줄 수를 고정해서 입력 중에도, 커서가 옮겨 다녀도 칸 크기가 변하지 않게 한다.
          minLines: 4,
          maxLines: 4,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              ChurchClosureRequest.maxReasonLength,
            ),
          ],
          decoration: const InputDecoration(
            labelText: '폐쇄 사유',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        AppField.spacer,
        TextField(
          controller: _confirm,
          maxLines: 1,
          decoration: InputDecoration(
            labelText: '확인을 위해 교회 이름을 입력하세요',
            hintText: widget.churchName,
            // 안내 글자가 생기고 사라져도 칸 높이가 바뀌지 않게 한다.
            hintMaxLines: 1,
          ),
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
              onPressed: _ready
                  ? () => Navigator.pop(context, _reason.text.trim())
                  : null,
              child: const Text('폐쇄 요청'),
            ),
          ],
        ),
      ],
    );
  }
}
