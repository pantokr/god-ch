import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/preferences_controller.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/choice_row.dart';

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
                  ],
                ),
                const SizedBox(height: 16),
                _ScreenGroup(
                  prefs: prefs,
                  title: '중보기도',
                  screen: 'prayer',
                  extras: [],
                ),
                const SizedBox(height: 16),
                _ScreenGroup(
                  prefs: prefs,
                  title: '말씀묵상',
                  screen: 'bible',
                  extras: [
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

/// 화면 하나의 묶음: 미리보기 하나와 그 아래 색상 · 글씨 크기 · 글꼴 팔레트, 그 화면만의 항목들.
class _ScreenGroup extends StatelessWidget {
  const _ScreenGroup({
    required this.prefs,
    required this.title,
    required this.screen,
    this.extras = const [],
  });

  final PreferencesController prefs;
  final String title;
  final String screen;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    final tint = prefs.tintOf(screen);
    final size = prefs.sizeOf(screen);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _Group(
      title: title,
      children: [
        _Palette(
          label: '색상',
          children: [
            for (final t in ScreenTint.values)
              _Swatch(
                tint: t,
                dark: dark,
                selected: t == tint,
                onTap: () => prefs.setTint(screen, t),
              ),
          ],
        ),
        _Palette(
          label: '글씨 크기',
          children: [
            for (final s in TextSize.values)
              _Choice(
                label: s.label,
                selected: s == size,
                onTap: () => prefs.setSize(screen, s),
                child: Text(
                  '가',
                  style: TextStyle(
                    fontSize: 14 * s.factor * 1.25,
                    color: context.palette.ink,
                  ),
                ),
              ),
          ],
        ),
        ...extras,
      ],
    );
  }
}

/// 팔레트 한 줄: 이름표(왼쪽 칸)와 선택지들이 한 줄에 놓인다 (좁으면 이름표가 위로 올라간다).
class _Palette extends StatelessWidget {
  const _Palette({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = Wrap(spacing: 10, runSpacing: 10, children: children);
    return LayoutBuilder(
      builder: (context, box) {
        final text = Text(
          label,
          style: TextStyle(
            color: context.palette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );
        if (box.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 8), items],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
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
    required this.dark,
    required this.selected,
    required this.onTap,
  });

  final ScreenTint tint;
  final bool dark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color =
        tint.colorFor(dark ? Brightness.dark : Brightness.light) ?? palette.bg;
    return Tooltip(
      message: tint.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
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
        width: 84,
        // 글씨가 커져도 넘치지 않게 높이는 최소값만 정한다.
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 6),
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
            child,
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
