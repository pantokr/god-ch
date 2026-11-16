import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/preferences_controller.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/choice_row.dart';
import '../../../core/widgets/labeled_field.dart';

/// 개인 설정: 이 기기에서만 쓰는 보기 취향. 왼쪽 서랍의 "개인 설정"으로 들어온다.
/// 앱 안의 다른 곳(화면 모드 버튼, 목록 모양 · 보기 · 정렬 버튼)에서 이미 고르는 것은 두지 않는다.
/// 중보기도 · 말씀묵상은 화면마다 미리보기 하나를 두고, 그 아래 색상 · 글씨 크기 · 글꼴 팔레트에서 고르면
/// 미리보기에 바로 반영되고 저장된다.
class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.read(context).preferences;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        return SingleChildScrollView(
          child: PageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Group(
                  title: '전체',
                  children: [
                    ChoiceRow<TextSize>(
                      label: '글씨 크기',
                      options: [
                        for (final s in TextSize.values)
                          ChoiceOption(s, s.label),
                      ],
                      value: prefs.textSize,
                      onChanged: prefs.setTextSize,
                    ),
                    // 글 · 댓글 · 알림의 작성 시각: 몇 분 전 / 11.09 14:05
                    ChoiceRow<DateStyle>(
                      label: '일시 표기',
                      options: [
                        for (final d in DateStyle.values)
                          ChoiceOption(d, d.label),
                      ],
                      value: prefs.dateStyle,
                      onChanged: prefs.setDateStyle,
                    ),
                    // 중보기도와 말씀묵상의 카드 글씨가 같은 크기를 쓴다 (아래 라디오 줄과 같은 칸에 놓인다).
                    _Palette(
                      label: '카드 글씨 크기',
                      cells: true,
                      children: [
                        for (final t in TextSize.values)
                          _Choice(
                            label: t.label,
                            selected: t == prefs.sizeOf('bible'),
                            onTap: () => prefs.setSize('bible', t),
                            child: Text(
                              '가',
                              style: TextStyle(
                                fontSize: 14 * t.factor * 1.25,
                                color: context.palette.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // 중보기도와 말씀묵상의 카드가 같은 색을 쓴다.
                    _Palette(
                      label: '카드 색상',
                      single: true,
                      children: [
                        for (final t in ScreenTint.values)
                          _Swatch(
                            tint: t,
                            selected: t == prefs.tintOf('bible'),
                            onTap: () => prefs.setTint('bible', t),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Group(
                  title: '말씀묵상',
                  children: [
                    ChoiceRow<DevotionDesign>(
                      label: '디자인',
                      options: [
                        for (final d in DevotionDesign.values)
                          ChoiceOption(d, d.label),
                      ],
                      value: prefs.devotionDesign,
                      onChanged: prefs.setDevotionDesign,
                    ),
                    ChoiceRow<bool>(
                      label: '책 이름',
                      options: const [
                        ChoiceOption(false, '전체'),
                        ChoiceOption(true, '약어'),
                      ],
                      value: prefs.abbreviateBooks,
                      onChanged: prefs.setAbbreviateBooks,
                    ),
                    OnOffRow(
                      label: '절 번호',
                      value: prefs.showVerseNumbers,
                      onChanged: prefs.setShowVerseNumbers,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 팔레트 한 줄: 이름표(왼쪽 칸)와 선택지들이 한 줄에 놓인다 (좁으면 이름표가 위로 올라간다).
/// [cells]면 선택지가 라디오 줄([ChoiceRadios])과 같은 칸 너비로 놓여, 줄이 달라도 같은 열에 맞는다.
class _Palette extends StatelessWidget {
  const _Palette({
    required this.label,
    required this.children,
    this.cells = false,
    this.single = false,
  });

  final String label;
  final List<Widget> children;
  final bool cells;

  /// 선택지(동그라미)가 줄바꿈 없이 한 줄에 다 놓인다.
  final bool single;

  static const _gap = 10.0;

  Widget _cellRow() => LayoutBuilder(
    builder: (context, box) {
      final cell = (box.maxWidth / ChoiceRadios.cellCount(children.length))
          .clamp(0.0, ChoiceRadios.cellWidth);
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in children)
              SizedBox(
                width: cell,
                child: Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: c,
                ),
              ),
          ],
        ),
      );
    },
  );

  /// 선택지가 늘 한 줄에 놓이게, 칸이 모자라면 동그라미 지름을 줄인다 (최대 [_Swatch.maxSize]).
  Widget _singleRow() => LayoutBuilder(
    builder: (context, box) {
      final n = children.length;
      final fit = (box.maxWidth - _gap * (n - 1)) / n;
      final size = fit.clamp(0.0, _Swatch.maxSize);
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              SizedBox(width: size, height: size, child: children[i]),
            ],
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final items = cells
        ? _cellRow()
        : single
        ? _singleRow()
        : Wrap(spacing: _gap, runSpacing: _gap, children: children);
    return LayoutBuilder(
      builder: (context, box) {
        final text = Text(
          label,
          style: TextStyle(color: context.palette.ink, fontSize: 14),
        );
        // 다른 선택 줄(ChoiceRow)과 같은 기준으로 이름표를 위로 올린다.
        if (box.maxWidth < LabeledField.narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 8), items],
          );
        }
        return Row(
          crossAxisAlignment: cells
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: LabeledField.labelWidth,
              child: Padding(
                padding: EdgeInsets.only(right: 12, top: cells ? 0 : 12),
                child: text,
              ),
            ),
            Expanded(child: items),
          ],
        );
      },
    );
  }
}

/// 색 팔레트의 색 하나: 그 색의 동그라미. 고른 것은 테두리가 진하다.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final ScreenTint tint;
  final bool selected;
  final VoidCallback onTap;

  /// 동그라미의 가장 큰 지름.
  static const maxSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // 다크 모드에서도 라이트 모드와 같은 색 팔레트가 보인다 (기본은 라이트의 바탕색).
    // 화면에 실제로 입히는 색은 어두운 쪽 짝이라 글자가 읽힌다.
    final color = tint.colorFor(Brightness.light) ?? AppPalette.light.bg;
    return Tooltip(
      message: tint.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 놓이는 칸(정사각형)을 가득 채운다: 칸 크기는 줄이 정한다 ([maxSize] 이하).
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? palette.ink : palette.border,
              width: selected ? 2.4 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 글씨 크기 · 글꼴 팔레트의 선택지 하나: 그 크기 · 글꼴의 글자와 이름. 고른 것은 테두리가 진하다.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 폭은 놓이는 칸을 가득 채우고, 높이는 글자 크기와 상관없이 모두 같다.
        // 고른 카드는 테두리가 두꺼워 그만큼 안쪽이 줄므로, 안 고른 카드에 같은 만큼 여백을 더해 크기를 맞춘다.
        padding: EdgeInsets.all(selected ? 0 : 1.4)
            .add(const EdgeInsets.symmetric(vertical: 8)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: selected ? palette.ink : palette.border,
            width: selected ? 2.4 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 가장 큰 글자(크게)가 들어가는 높이로 고정해, 작게 · 보통 · 크게 카드가 같은 높이가 된다.
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(30),
              child: Center(child: child),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? palette.ink : palette.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 한 묶음: 제목과 카드 안의 줄들.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppField.gap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
