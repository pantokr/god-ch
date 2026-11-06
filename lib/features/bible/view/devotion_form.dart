import 'package:flutter/material.dart';

import '../../../core/layout/sub_page.dart';

import '../../../core/widgets/choice_row.dart';

import '../../../core/widgets/labeled_field.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_content.dart';
import 'bible_picker_dialog.dart';

/// 말씀 추가 · 수정에서 입력한 값.
class DevotionFormResult {
  const DevotionFormResult(
    this.title,
    this.body,
    this.meditation,
    this.date, {
    this.affiliationId,
    this.isPrivate = false,
  });

  final String title;
  final String body;
  final String meditation;
  final DateTime date;

  /// 분류한 소속. null이면 교회 전체.
  final String? affiliationId;

  /// 비공개 (말씀묵상 비공개 조회 권한이 있는 사람만 볼 수 있다).
  final bool isPrivate;
}

/// 말씀 추가 · 수정 화면. 중보기도 쓰기와 같은 모양의 페이지(뒤로가기 + 카드 안의 폼)다. 취소하면 null.
Future<DevotionFormResult?> showDevotionForm(
  BuildContext context, {
  required String churchId,

  /// 소속 선택에 올릴 수 있는 소속인가 (교회 관리자는 모두, 그 밖에는 자기 소속만).
  required bool Function(Affiliation) visible,
  ChurchContent? initial,
  // 중보기도 쓰기와 같이 상단 탭이 없는 전체 화면으로 연다 (가장 바깥 Navigator).
}) => Navigator.of(context, rootNavigator: true).push<DevotionFormResult>(
  MaterialPageRoute(
    builder: (_) => Builder(
      builder: (context) => SubPage(
        title: '',
        barTitle: initial == null ? '말씀묵상 작성' : '말씀묵상 수정',
        fallbackLocation: '',
        onBack: () => Navigator.of(context).maybePop(),
        child: _Form(churchId: churchId, visible: visible, initial: initial),
      ),
    ),
  ),
);

class _Form extends StatefulWidget {
  const _Form({required this.churchId, required this.visible, this.initial});

  final String churchId;
  final bool Function(Affiliation) visible;
  final ChurchContent? initial;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  // 구절과 말씀은 직접 쓰지 않고 성경에서 불러온다.
  late String _verse = widget.initial?.title ?? '';
  late String _verseText = widget.initial?.body ?? '';
  late final _verseField = TextEditingController(text: _verse);
  late final _meditation = TextEditingController(
    text: widget.initial?.meditation,
  );
  late final DateTime _date = widget.initial?.date ?? DateTime.now();
  late String? _affiliationId = widget.initial?.affiliationId;
  late bool _private = widget.initial?.isPrivate ?? false;

  @override
  void dispose() {
    _verseField.dispose();
    _meditation.dispose();
    super.dispose();
  }

  /// 성경 구절을 골라 불러온다: 구절 이름과 본문이 함께 들어온다.
  Future<void> _pickVerse() async {
    final pick = await showAppDialog<BiblePick>(
      context,
      child: const BiblePickerDialog(),
    );
    if (pick == null) return;
    setState(() {
      _verse = pick.title;
      _verseField.text = pick.title;
      _verseText = pick.body;
    });
  }

  /// 불러온 성경 본문을 읽어 본다.
  void _viewVerse() => showAppDialog<void>(
    context,
    child: Builder(
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_verse, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SelectableText(_verseText, style: readingStyle(context)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 한 줄: 불러오기 버튼 + 읽기 전용 입력칸 (불러온 구절이 채워지고, 오른쪽 끝에 읽기 버튼이 붙어 있다).
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onPressed: _pickVerse,
                        child: const Text('불러오기'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _verseField,
                          readOnly: true,
                          decoration: InputDecoration(
                            suffixIcon: TextButton(
                              onPressed: _verseText.isEmpty ? null : _viewVerse,
                              child: const Text('읽기'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                LabeledField(
                  label: '묵상',
                  stacked: true,
                  child: TextField(
                    controller: _meditation,
                    minLines: 9,
                    maxLines: 24,
                    maxLength: 5000,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '10자 이상',

                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 소속 · 공개 범위 · 저장은 본문 카드와 분리한 카드에 둔다.
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<List<Affiliation>>(
                  stream: AppScope.read(context).affiliations
                      .affiliations(widget.churchId),
                  builder: (context, snap) {
                    final list = [
                      for (final a in snap.data ?? const <Affiliation>[])
                        if (widget.visible(a)) a,
                    ];
                    if (list.isEmpty) return const SizedBox.shrink();
                    // 교회 전체는 고를 수 없다: 고른 소속이 없으면 첫 소속이 골라진다.
                    final chosen = list.any((a) => a.id == _affiliationId);
                    if (!chosen) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _affiliationId = list.first.id);
                        }
                      });
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: LabeledField(
                        label: '공개 범위',
                        child: DropdownButtonFormField<String?>(
                          initialValue: chosen ? _affiliationId : list.first.id,
                          decoration: const InputDecoration(),
                          items: [
                            for (final a in list)
                              DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => _affiliationId = v),
                        ),
                      ),
                    );
                  },
                ),
                // 비공개: 말씀묵상 비공개 조회 권한이 있는 사람(교역자)만 볼 수 있다.
                ChoiceRow<bool>(
                  label: '공개 여부',
                  options: const [
                    ChoiceOption(false, '공개'),
                    ChoiceOption(true, '교역자 전용'),
                  ],
                  value: _private,
                  onChanged: (v) => setState(() => _private = v),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed:
                          _verseText.isEmpty ||
                              _meditation.text.trim().length <
                                  ChurchContent.minMeditation
                          ? null
                          : () => Navigator.pop(
                              context,
                              DevotionFormResult(
                                _verse,
                                _verseText,
                                _meditation.text,
                                _date,
                                affiliationId: _affiliationId,
                                isPrivate: _private,
                              ),
                            ),
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
