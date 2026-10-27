import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../../data/models/member.dart';
import '../view_model/devotion_reflections_view_model.dart';
import 'block_theme.dart';

/// 디자인 견본에 쓰는 남겨진 글 (실제 저장소를 읽지 않는다).
const sampleReflections = [
  DevotionReflection(
    authorId: 'sample1',
    authorName: '김은혜',
    text: '요즘 마음이 분주했는데, 이 말씀으로 잠잠히 쉬어 갑니다.',
  ),
];

/// 실제 화면의 말씀묵상 한 편: 말씀 구절 한 단락과 그 아래에 교인들이 남긴 글, 내 글 쓰는 칸.
/// 남겨진 글은 저장소에서 실시간으로 읽는다.
class DevotionBlockItem extends StatelessWidget {
  const DevotionBlockItem({
    super.key,
    required this.variant,
    required this.content,
    required this.me,
    required this.onOpen,
    required this.theme,
  });

  final String variant;
  final BlockTheme theme;
  final ChurchContent content;
  final Member me;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DevotionReflectionsViewModel>(
      key: ValueKey('${content.id}/${me.id}'),
      create: (context) => DevotionReflectionsViewModel(
        AppScope.read(context).reflections,
        me,
        content.id,
      ),
      builder: (context, vm) => StreamBuilder<List<DevotionReflection>>(
        stream: vm.reflections,
        builder: (context, snap) => DevotionDesign(
          variant: variant,
          theme: theme,
          content: content,
          reflections: snap.data ?? const [],
          myId: me.id,
          canModerate: me.isStaff,
          busy: vm.busy,
          error: vm.error,
          onOpen: onOpen,
          onSave: vm.save,
          onDelete: vm.delete,
        ),
      ),
    );
  }
}

/// 말씀묵상 한 편을 그리는 디자인들. 말씀 구절을 한 단락 놓고, 그 아래에 내 글 쓰는 칸과 남겨진 글을 둔다.
/// 디자인마다 구절 단락을 놓는 모양이 다르다.
/// - card: 구절 줄 + 본문 (기본).
/// - quote: 큰 따옴표와 크게 쓴 구절 이름.
/// - field: 구절 이름을 이름표로 단 입력칸 모양의 상자 안에 본문.
/// - note: 줄 노트 위에 구절.
/// - split: 왼쪽에 구절 이름, 오른쪽 입력칸 모양의 상자에 본문.
/// - twin·twin_quote·twin_note: 긴 여러 절(카드 · 인용형 · 줄 노트형 모양)과 내 묵상을 두 카드로 나눠 반반 (좁으면 위아래).
/// [onSave]가 null이면 견본이라서 쓰기 칸이 눌리지 않는다.
class DevotionDesign extends StatefulWidget {
  const DevotionDesign({
    super.key,
    required this.variant,
    required this.theme,
    required this.content,
    required this.reflections,
    this.myId = '',
    this.canModerate = false,
    this.busy = false,
    this.error,
    this.onOpen,
    this.onSave,
    this.onDelete,
  });

  final String variant;

  /// 스타일·팔레트로 만든 색 구성. 이 디자인 안에서는 앱 팔레트 대신 이것을 쓴다.
  final BlockTheme theme;
  final ChurchContent content;
  final List<DevotionReflection> reflections;
  final String myId;
  final bool canModerate;
  final bool busy;
  final String? error;
  final VoidCallback? onOpen;
  final Future<bool> Function(String text)? onSave;
  final Future<bool> Function(String authorId)? onDelete;

  @override
  State<DevotionDesign> createState() => _DevotionDesignState();
}

class _DevotionDesignState extends State<DevotionDesign> {
  late final TextEditingController _text = TextEditingController(
    text: _mine?.text,
  );

  DevotionReflection? get _mine {
    for (final r in widget.reflections) {
      if (r.authorId == widget.myId) return r;
    }
    return null;
  }

  @override
  void didUpdateWidget(DevotionDesign old) {
    super.didUpdateWidget(old);
    // 내 글이 나중에 도착하면(처음 불러올 때) 쓰는 칸에 채워 준다. 쓰던 글은 건드리지 않는다.
    if (_text.text.isEmpty && _mine != null) _text.text = _mine!.text;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await widget.onSave!(_text.text);
    if (ok && mounted) FocusScope.of(context).unfocus();
  }

  /// 면 하나: 스타일에 맞는 면 · 테두리 · 그림자.
  Widget _card(BuildContext context, Widget child) {
    return DecoratedBox(
      decoration: widget.theme.card(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }

  /// 내 글 쓰는 칸 + 오류 + 남겨진 글.
  List<Widget> _reflectionParts(BuildContext context) => [
    _myField(context),
    if (widget.error != null)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          widget.error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ..._others(context),
  ];

  /// 이 디자인 안의 글자·입력칸·버튼·구분선이 고른 스타일의 색을 따르도록 테마를 덮어쓴다.
  ThemeData _themed(BuildContext context) {
    final t = widget.theme;
    final base = Theme.of(context);
    return base.copyWith(
      extensions: [
        AppPalette(
          ink: t.text,
          muted: t.sub,
          bg: t.surface,
          surface: t.surface,
          border: t.border,
          brand: t.accent,
          onBrand: t.onAccent,
          accent: t.accent2,
        ),
      ],
      textTheme: base.textTheme.apply(bodyColor: t.text, displayColor: t.text),
      colorScheme: base.colorScheme.copyWith(
        primary: t.accent,
        onPrimary: t.onAccent,
        onSurface: t.text,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: t.text.withValues(alpha: 0.07),
        labelStyle: TextStyle(color: t.sub.withValues(alpha: 0.8)),
        floatingLabelStyle: TextStyle(color: t.accent),
        counterStyle: const TextStyle(fontSize: 0, height: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _themed(context),
    child: Builder(builder: _content),
  );

  Widget _content(BuildContext context) {
    if (widget.variant.startsWith('twin')) return _twin(context);
    final palette = context.palette;
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(onTap: widget.onOpen, child: _verse(context)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: palette.border),
          ),
          ..._reflectionParts(context),
        ],
      ),
    );
  }

  /// 두 카드 반반: 긴 여러 절은 왼쪽 카드, 내 묵상과 남겨진 글은 오른쪽 카드. 좁은 화면에서는 위아래로.
  Widget _twin(BuildContext context) {
    final palette = context.palette;
    // 왼쪽 카드의 말씀 모양은 대응하는 한 카드 디자인(card · quote · note)과 같다.
    final base = widget.variant == 'twin'
        ? 'card'
        : widget.variant.substring('twin_'.length);
    final passage = _card(
      context,
      InkWell(
        onTap: widget.onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 여러 절이 길어도 잘리지 않게 줄 수를 넉넉히 둔다.
            switch (base) {
              'quote' => _quote(context, maxLines: 40),
              'note' => _note(context, maxLines: 40),
              _ => _cardVerse(context, maxLines: 40),
            },
            if (base != 'card') ...[
              const SizedBox(height: 12),
              Text(
                fmtDate(widget.content.date),
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
    final mine = _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _reflectionParts(context),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [passage, const SizedBox(height: 12), mine],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: passage),
              const SizedBox(width: 12),
              Expanded(child: mine),
            ],
          ),
        );
      },
    );
  }

  // ---- 말씀 구절 단락 ----

  Widget _passage(BuildContext context, {int maxLines = 6}) => Text(
    widget.content.body,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: readingStyle(context),
  );

  Widget _verse(BuildContext context) => switch (widget.variant) {
    'quote' => _quote(context),
    'note' => _note(context),
    _ => _cardVerse(context),
  };

  Widget _cardVerse(BuildContext context, {int maxLines = 6}) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 18, color: palette.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.content.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 17),
              ),
            ),
            Text(
              fmtDate(widget.content.date),
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
        if (widget.content.body.isNotEmpty) ...[
          const SizedBox(height: 12),
          _passage(context, maxLines: maxLines),
        ],
      ],
    );
  }

  Widget _quote(BuildContext context, {int maxLines = 6}) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“',
          style: TextStyle(
            color: palette.brand,
            fontSize: 56,
            height: 0.8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.content.title,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: palette.brand, fontSize: 24),
        ),
        if (widget.content.body.isNotEmpty) ...[
          const SizedBox(height: 12),
          _passage(context, maxLines: maxLines),
        ],
      ],
    );
  }

  Widget _note(BuildContext context, {int maxLines = 6}) {
    final palette = context.palette;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 3, color: palette.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content.title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontSize: 18),
                ),
                Divider(color: palette.border, height: 20, thickness: 1.5),
                _passage(context, maxLines: maxLines),
                Divider(color: palette.border, height: 20, thickness: 1.5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- 내 글 쓰는 칸 ----

  Widget _myField(BuildContext context) {
    final enabled = widget.onSave != null && !widget.busy;
    final mine = _mine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _text,
          enabled: widget.onSave != null,
          minLines: 3,
          maxLines: 6,
          maxLength: DevotionReflection.maxLength,
          decoration: InputDecoration(
            labelText: '내 묵상',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (mine != null && widget.onDelete != null)
              TextButton(
                onPressed: widget.busy
                    ? null
                    : () async {
                        if (await widget.onDelete!(mine.authorId)) {
                          _text.clear();
                        }
                      },
                child: const Text('지우기'),
              ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: enabled ? _save : null,
              child: Text(mine == null ? '남기기' : '고치기'),
            ),
          ],
        ),
      ],
    );
  }

  // ---- 다른 교인들이 남긴 글 ----

  List<Widget> _others(BuildContext context) {
    final palette = context.palette;
    final others = [
      for (final r in widget.reflections)
        if (r.authorId != widget.myId) r,
    ].take(5).toList();
    if (others.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      for (final r in others)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                palette.brand.withValues(alpha: 0.05),
                palette.surface,
              ),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.authorName.isEmpty ? '이름 없음' : r.authorName,
                          style: TextStyle(
                            color: palette.brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(r.text),
                      ],
                    ),
                  ),
                  if (widget.canModerate && widget.onDelete != null)
                    IconButton(
                      tooltip: '지우기',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: widget.busy
                          ? null
                          : () => widget.onDelete!(r.authorId),
                    ),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}
