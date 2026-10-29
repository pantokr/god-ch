import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../../data/models/member.dart';
import '../../home/view_model/devotion_reflections_view_model.dart';

/// 말씀 한 편의 댓글: 내 묵상 쓰는 칸과 교인들이 남긴 글. 한 사람이 한 편에 하나를 쓰고 고친다.
/// 남겨진 글은 저장소에서 실시간으로 읽는다. 교역자는 남의 글도 지울 수 있다.
class ReflectionsCard extends StatelessWidget {
  const ReflectionsCard({
    super.key,
    required this.devotionId,
    required this.me,
  });

  final String devotionId;
  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DevotionReflectionsViewModel>(
      key: ValueKey('$devotionId/${me.id}'),
      create: (context) => DevotionReflectionsViewModel(
        AppScope.read(context).reflections,
        me,
        devotionId,
      ),
      builder: (context, vm) => StreamBuilder<List<DevotionReflection>>(
        stream: vm.reflections,
        builder: (context, snap) => _Body(
          reflections: snap.data ?? const [],
          me: me,
          busy: vm.busy,
          error: vm.error,
          onSave: vm.save,
          onDelete: vm.delete,
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({
    required this.reflections,
    required this.me,
    required this.busy,
    required this.error,
    required this.onSave,
    required this.onDelete,
  });

  final List<DevotionReflection> reflections;
  final Member me;
  final bool busy;
  final String? error;
  final Future<bool> Function(String text) onSave;
  final Future<bool> Function(String authorId) onDelete;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TextEditingController _text = TextEditingController(
    text: _mine?.text,
  );

  DevotionReflection? get _mine {
    for (final r in widget.reflections) {
      if (r.authorId == widget.me.id) return r;
    }
    return null;
  }

  @override
  void didUpdateWidget(_Body old) {
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
    final ok = await widget.onSave(_text.text);
    if (ok && mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mine = _mine;
    final others = [
      for (final r in widget.reflections)
        if (r.authorId != widget.me.id) r,
    ].take(20).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.messageCircle, size: 18, color: palette.accent),
                const SizedBox(width: 8),
                Text(
                  '댓글 ${widget.reflections.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _text,
              minLines: 2,
              maxLines: 6,
              maxLength: DevotionReflection.maxLength,
              decoration: const InputDecoration(
                labelText: '내 묵상',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (mine != null)
                  TextButton(
                    onPressed: widget.busy
                        ? null
                        : () async {
                            if (await widget.onDelete(mine.authorId)) {
                              _text.clear();
                            }
                          },
                    child: const Text('지우기'),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: widget.busy ? null : _save,
                  child: Text(mine == null ? '남기기' : '고치기'),
                ),
              ],
            ),
            if (widget.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (others.isNotEmpty) const SizedBox(height: 12),
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
                        if (widget.me.isStaff)
                          IconButton(
                            tooltip: '지우기',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(AppIcons.trash, size: 18),
                            onPressed: widget.busy
                                ? null
                                : () => widget.onDelete(r.authorId),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
