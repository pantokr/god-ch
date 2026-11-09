import 'package:flutter/material.dart';

import '../../../core/layout/discard_guard.dart';
import '../../../core/icons.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/widgets/trash_icon.dart';

import '../../../core/widgets/char_counter.dart';
import '../../../core/widgets/choice_row.dart';

import '../../../core/widgets/labeled_field.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_content.dart';
import 'bible_picker_dialog.dart';

/// 말씀 추가 · 수정에서 입력한 값. 첫 말씀 · 묵상은 [title] · [body] · [meditation]에, 둘째부터는 [extras]에 있다.
class DevotionFormResult {
  const DevotionFormResult(
    this.title,
    this.body,
    this.meditation,
    this.date, {
    this.extras = const [],
    this.affiliationId,
    this.isPrivate = false,
  });

  final String title;
  final String body;
  final String meditation;
  final List<DevotionPassage> extras;
  final DateTime date;

  /// 분류한 소속. 글마다 하나가 꼭 있다.
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

/// 작성 중인 말씀 · 묵상 한 벌: 불러온 구절과 본문, 묵상 입력칸.
class _Passage {
  _Passage({String verse = '', this.verseText = '', String meditation = ''})
    : verse = verse,
      verseField = TextEditingController(text: verse),
      meditation = TextEditingController(text: meditation);

  String verse;
  String verseText;
  final TextEditingController verseField;
  final TextEditingController meditation;

  bool get complete =>
      verseText.isNotEmpty &&
      meditation.text.trim().length >= ChurchContent.minMeditation;

  DevotionPassage toPassage() => DevotionPassage(
    title: verse,
    body: verseText,
    meditation: meditation.text,
  );

  void dispose() {
    verseField.dispose();
    meditation.dispose();
  }
}

class _FormState extends State<_Form> {
  // 구절과 말씀은 직접 쓰지 않고 성경에서 불러온다. 한 글에 말씀 · 묵상을 최대 10벌까지 담는다.
  late final List<_Passage> _passages = [
    for (final p in widget.initial?.passages ?? const <DevotionPassage>[])
      _Passage(verse: p.title, verseText: p.body, meditation: p.meditation),
    if (widget.initial == null) _Passage(),
  ];
  late final DateTime _date = widget.initial?.date ?? DateTime.now();
  late String? _affiliationId = widget.initial?.affiliationId;
  late bool _private = widget.initial?.isPrivate ?? false;

  @override
  void dispose() {
    for (final p in _passages) {
      p.dispose();
    }
    super.dispose();
  }

  /// 성경 구절을 골라 불러온다: 구절 이름과 본문이 함께 들어온다.
  Future<void> _pickVerse(_Passage p) async {
    final pick = await showAppDialog<BiblePick>(
      context,
      // 이미 불러온 구절이 있으면(수정) 불러오기를 누르자마자 그 구절이 골라져 있다.
      child: BiblePickerDialog(initialTitle: p.verse),
    );
    if (pick == null) return;
    setState(() {
      p.verse = pick.title;
      p.verseField.text = pick.title;
      p.verseText = pick.body;
    });
  }

  /// 불러온 성경 본문을 읽어 본다: 제목 없이 말씀 종이 위에 구절과 본문이 크게 보인다.
  void _viewVerse(_Passage p) => showAppDialog<void>(
    context,
    child: VerseReader(title: p.verse, body: p.verseText),
  );

  void _addPassage() {
    if (_passages.length >= ChurchContent.maxPassages) return;
    setState(() => _passages.add(_Passage()));
  }

  void _removePassage(int i) {
    final p = _passages.removeAt(i);
    setState(() {});
    // 입력칸은 다음 틀에서 내려가므로 한 프레임 뒤에 정리한다.
    WidgetsBinding.instance.addPostFrameCallback((_) => p.dispose());
  }

  bool get _dirty {
    final init = widget.initial?.passages ?? const <DevotionPassage>[];
    if (_passages.length != (init.isEmpty ? 1 : init.length)) return true;
    for (var i = 0; i < _passages.length; i++) {
      final p = _passages[i];
      final o = i < init.length ? init[i] : null;
      if (p.verse != (o?.title ?? '') ||
          p.meditation.text != (o?.meditation ?? '')) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return DiscardGuard(
      isDirty: () => _dirty,
      listenable: Listenable.merge([for (final p in _passages) p.meditation]),
      child: _content(context),
    );
  }

  /// 말씀 · 묵상 한 벌의 카드. 둘째부터는 오른쪽 위에 지우기 버튼이 있다.
  Widget _passageCard(int i) {
    final p = _passages[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_passages.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '묵상 ${i + 1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (i > 0)
                      TextButton.icon(
                        style: TrashIcon.textStyle(context),
                        onPressed: () => _removePassage(i),
                        icon: const TrashIcon(size: 16),
                        label: const Text('삭제'),
                      ),
                  ],
                ),
              ),
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
                    onPressed: () => _pickVerse(p),
                    child: const Text('불러오기'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: p.verseField,
                      readOnly: true,
                      decoration: InputDecoration(
                        suffixIcon: TextButton(
                          onPressed: p.verseText.isEmpty
                              ? null
                              : () => _viewVerse(p),
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
                controller: p.meditation,
                minLines: 9,
                maxLines: 24,
                maxLength: 5000,
                buildCounter: charCounter,
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
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _passages.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _passageCard(i),
        ],
        const SizedBox(height: 12),
        // 한 글에 묵상을 여러 군데 담는다 (최대 10개).
        OutlinedButton.icon(
          onPressed: _passages.length >= ChurchContent.maxPassages
              ? null
              : _addPassage,
          icon: const Icon(AppIcons.plus, size: 18),
          label: Text(
            '묵상 추가 (${_passages.length}/${ChurchContent.maxPassages})',
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
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed:
                          // 글마다 소속이 하나 있어야 하고, 모든 묵상이 채워져 있어야 한다.
                          _affiliationId == null ||
                              _passages.any((p) => !p.complete)
                          ? null
                          : () {
                              final first = _passages.first;
                              Navigator.pop(
                                context,
                                DevotionFormResult(
                                  first.verse,
                                  first.verseText,
                                  first.meditation.text,
                                  _date,
                                  extras: [
                                    for (final p in _passages.skip(1))
                                      p.toPassage(),
                                  ],
                                  affiliationId: _affiliationId,
                                  isPrivate: _private,
                                ),
                              );
                            },
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
