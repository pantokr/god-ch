import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/char_counter.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/toast.dart';
import '../../../data/models/inquiry.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/inquiry_view_models.dart';

/// 문의: 앱 운영자에게 문의를 보내고, 내가 보낸 문의와 답변을 본다.
/// 앱 정보 창의 문의하기 버튼이 연다.
class InquiryPage extends StatelessWidget {
  const InquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<InquiryViewModel>(
      create: (context) => InquiryViewModel(AppScope.read(context).inquiries),
      builder: (context, vm) => SubPage(
        title: '문의',
        barTitle: '문의',
        fallbackLocation: Routes.churches,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Form(vm: vm),
            const SizedBox(height: 28),
            Gutter(
              child: Text(
                '내 문의',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Inquiry>>(
              stream: vm.mine,
              builder: (context, snap) {
                if (snap.hasError) {
                  return EmptyHint('불러오지 못했습니다\n${snap.error}');
                }
                final items = snap.data;
                if (items == null) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: AppLoader()),
                  );
                }
                if (items.isEmpty) return const EmptyHint('문의 없음');
                return Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _MineTile(item: items[i], vm: vm),
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
    );
  }
}

/// 보내기 칸: 제목 · 내용 · 보내기.
class _Form extends StatefulWidget {
  const _Form({required this.vm});

  final InquiryViewModel vm;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _title = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _ready =>
      _title.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.vm.send(_title.text, _message.text);
    if (!ok || !mounted) return;
    _title.clear();
    _message.clear();
    setState(() {});
    showToastOn(messenger, '문의를 보냈어요');
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    // 다른 글 작성 페이지처럼 카드 너비를 전부 쓰는 입력칸 (이름표는 칸 위에).
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: '제목',
              stacked: true,
              child: TextField(
                controller: _title,
                maxLines: 1,
                maxLength: Inquiry.maxTitle,
                buildCounter: charCounter,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 20),
            LabeledField(
              label: '내용',
              stacked: true,
              child: TextField(
                controller: _message,
                minLines: 8,
                maxLines: 16,
                maxLength: Inquiry.maxMessage,
                buildCounter: charCounter,
                decoration: const InputDecoration(alignLabelWithHint: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 8),
              Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: vm.busy || !_ready ? null : _send,
                child: const Text('보내기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 내가 보낸 문의 한 건: 제목과 상태, 펼치면 내용과 답변.
class _MineTile extends StatelessWidget {
  const _MineTile({required this.item, required this.vm});

  final Inquiry item;
  final InquiryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final muted = TextStyle(color: palette.muted, fontSize: 13);
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${item.answered ? '답변 완료' : '답변 대기'} · ${fmtPosted(item.createdAt)}',
          style: TextStyle(
            color: item.answered ? palette.brand : palette.muted,
            fontSize: 12.5,
          ),
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(item.message),
        if (item.answered) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('답변 · ${fmtPosted(item.answeredAt)}', style: muted),
                const SizedBox(height: 6),
                SelectableText(item.answer),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: vm.busy
                ? null
                : () async {
                    final ok = await confirmChange(
                      context,
                      title: '문의 삭제',
                      confirmLabel: '삭제',
                      danger: true,
                    );
                    if (ok) await vm.remove(item);
                  },
            child: const Text('삭제'),
          ),
        ),
      ],
    );
  }
}
