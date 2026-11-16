import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/char_counter.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../core/widgets/toast.dart';
import '../../../data/models/inquiry.dart';
import '../../home/view/content_widgets.dart';
import '../../inquiry/view_model/inquiry_view_models.dart';

/// 앱 운영자 > 문의: 회원이 보낸 문의를 최신 순으로 보고 답변한다.
class InquiriesPage extends StatelessWidget {
  const InquiriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<InquiryAdminViewModel>(
      create: (context) =>
          InquiryAdminViewModel(AppScope.read(context).inquiries),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SortStrip(
                options: [
                  PadOption(
                    '전체',
                    selected: vm.answered == null,
                    onTap: () => vm.setAnswered(null),
                  ),
                  PadOption(
                    '답변 대기',
                    selected: vm.answered == false,
                    onTap: () => vm.setAnswered(false),
                  ),
                  PadOption(
                    '답변 완료',
                    selected: vm.answered == true,
                    onTap: () => vm.setAnswered(true),
                  ),
                ],
              ),
              StreamBuilder<List<Inquiry>>(
                stream: vm.all,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return EmptyHint('불러오지 못했습니다\n${snap.error}');
                  }
                  final all = snap.data;
                  if (all == null) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    );
                  }
                  final items = vm.apply(all);
                  if (items.isEmpty) {
                    return EmptyHint(all.isEmpty ? '문의 없음' : '해당하는 문의 없음');
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _Row(item: items[i], vm: vm),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// 문의 한 줄: 제목, 보낸 사람 · 일시, 상태. 누르면 내용과 답변 칸이 열린다.
class _Row extends StatelessWidget {
  const _Row({required this.item, required this.vm});

  final Inquiry item;
  final InquiryAdminViewModel vm;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () => showAppDialog<void>(
        context,
        maxWidth: 520,
        child: _Detail(item: item, vm: vm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.userName.isEmpty ? '이름 없음' : item.userName} · ${fmtPosted(item.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.answered ? '답변 완료' : '답변 대기',
              style: TextStyle(
                color: item.answered ? palette.muted : palette.accent,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 문의 내용과 답변 칸. 답변을 보내면 닫히고, 이미 답변이 있으면 고쳐서 다시 보낼 수 있다.
class _Detail extends StatefulWidget {
  const _Detail({required this.item, required this.vm});

  final Inquiry item;
  final InquiryAdminViewModel vm;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  late final _answer = TextEditingController(text: widget.item.answer);

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.vm.reply(widget.item, _answer.text);
    if (!ok) return;
    navigator.pop();
    showToastOn(messenger, '답변을 보냈어요');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DialogTitle(item.title, gap: 4),
        Text(
          '${item.userName.isEmpty ? '이름 없음' : item.userName} · ${fmtPosted(item.createdAt)}',
          style: TextStyle(color: palette.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        SelectableText(item.message),
        const SizedBox(height: 20),
        TextField(
          controller: _answer,
          autofocus: !item.answered,
          minLines: 5,
          maxLines: 5,
          maxLength: Inquiry.maxAnswer,
          buildCounter: charCounter,
          decoration: const InputDecoration(
            hintText: '답변',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (widget.vm.error != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.vm.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        DialogActions(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: widget.vm.busy || _answer.text.trim().isEmpty
                  ? null
                  : _send,
              child: Text(item.answered ? '답변 수정' : '답변 보내기'),
            ),
          ],
        ),
      ],
    );
  }
}
