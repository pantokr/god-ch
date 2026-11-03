import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../icons.dart';
import '../layout/page_frame.dart';
import '../theme.dart';

/// 정렬 패드의 선택지 하나: 고른 것은 굵고 밑줄, 나머지는 보통 굵기. 글자는 모두 검은색이다.
class PadOption {
  const PadOption(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// 패드의 한 줄: 왼쪽 설명 글자([label])와 그 오른쪽 선택지들.
class PadGroup {
  const PadGroup(this.options, {this.label});

  /// 줄 왼쪽에 놓는 설명 (예: "정렬 순서"). 없으면 선택지만 나온다.
  final String? label;
  final List<PadOption> options;
}

/// 목록 위의 정렬 · 분류 패드. 일정 · 중보기도 · 말씀묵상 · 내 활동이 같은 모양을 쓴다.
/// [header](검색창 등)는 패널 밖 바로 위에 따로 놓이고, 각진 테두리 상자 안에는 줄들이 쌓인다. 쓰는 필드만 줄로 넣는다.
/// 줄마다 왼쪽에 설명 글자가 있고 선택지는 텍스트 버튼이고, 한 줄에 다 안 들어가면 줄바꿈 없이 좌우로 민다. 글자는 검은색(본문 글자색)이다.
class SortPad extends StatelessWidget {
  const SortPad({super.key, this.header, required this.groups});

  /// 줄 위에 놓는 위젯 (예: 검색창).
  final Widget? header;

  /// 줄들 (예: 소속 줄, 정렬 순서 줄). 선택지가 없는 줄은 그리지 않는다.
  final List<PadGroup> groups;

  /// 모서리 반지름 (각진 모양).
  static const radius = 4.0;

  /// 검색창(머리)과 패널 사이 간격.
  static const headerGap = 12.0;

  /// 줄(소속 · 정렬 순서 등) 한 줄의 높이와 줄 사이 간격. 글자 버튼 높이(40)에 맞춘 원래 간격이다.
  static const rowHeight = 40.0;
  static const rowGap = 6.0;

  /// 설명 글자 칸 너비.
  static const labelWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = [
      for (final g in groups)
        if (g.options.isNotEmpty) g,
    ];
    final hasLabels = rows.any((g) => g.label != null);
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: rowGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLabels)
                    // 설명 글자는 옅은 바탕 칩 위에 놓아 선택지와 구별한다.
                    SizedBox(
                      width: labelWidth,
                      height: rowHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(radius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            child: Text(
                              rows[i].label ?? '',
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 선택지가 많아도 다음 줄로 넘치지 않고 좌우로 밀어서 본다 (끝이 가려지면 화살표로 알린다).
                  Expanded(child: _SlideRow(options: rows[i].options)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
    if (header != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PadSearchField(child: header!),
          if (rows.isNotEmpty) ...[const SizedBox(height: headerGap), box],
        ],
      );
    }
    // 줄이 하나도 없으면 빈 상자를 그리지 않는다.
    return rows.isEmpty ? const SizedBox.shrink() : box;
  }
}

/// 검색 필드: 다른 입력칸과 같은 모양에 안쪽 여백만 넉넉하다. 안의 [TextField]에 입힌다.
class PadSearchField extends StatelessWidget {
  const PadSearchField({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Gutter(
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({required this.option});

  final PadOption option;

  @override
  Widget build(BuildContext context) {
    final on = option.selected;
    return TextButton(
      onPressed: option.onTap,
      style: TextButton.styleFrom(foregroundColor: context.palette.ink),
      child: Text(
        option.label,
        style: TextStyle(
          fontWeight: on ? FontWeight.w800 : FontWeight.w500,
          decoration: on ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );
  }
}

/// 좌우로 미는 선택지 줄. 더 밀 수 있는 쪽 끝에는 바탕색으로 사라지는 그림자와 화살표가 나와
/// 미끄러진다는 것을 알린다 (화살표를 누르면 그쪽으로 밀린다).
class _SlideRow extends StatefulWidget {
  const _SlideRow({required this.options});

  final List<PadOption> options;

  @override
  State<_SlideRow> createState() => _SlideRowState();
}

class _SlideRowState extends State<_SlideRow> {
  final _controller = ScrollController();
  bool _more = false; // 오른쪽에 더 있다
  bool _back = false; // 왼쪽으로 밀려 있다

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(_SlideRow old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final m = _controller.position;
    final more = m.pixels < m.maxScrollExtent - 1;
    final back = m.pixels > 1;
    if (more != _more || back != _back) {
      setState(() {
        _more = more;
        _back = back;
      });
    }
  }

  void _nudge(double direction) {
    final m = _controller.position;
    _controller.animateTo(
      (m.pixels + direction * 140).clamp(0.0, m.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget edge({required bool right}) => Positioned(
      top: 0,
      bottom: 0,
      left: right ? null : 0,
      right: right ? 0 : null,
      child: GestureDetector(
        onTap: () => _nudge(right ? 1 : -1),
        child: Container(
          width: 36,
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: right ? Alignment.centerLeft : Alignment.centerRight,
              end: right ? Alignment.centerRight : Alignment.centerLeft,
              colors: [palette.surface.withValues(alpha: 0), palette.surface],
            ),
          ),
          child: Icon(
            right ? AppIcons.caretRight : AppIcons.caretLeft,
            size: 18,
            color: palette.ink,
          ),
        ),
      ),
    );
    return SizedBox(
      height: SortPad.rowHeight,
      child: Stack(
        children: [
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _update());
              return false;
            },
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var k = 0; k < widget.options.length; k++) ...[
                    if (k > 0) const SizedBox(width: 4),
                    _PadButton(option: widget.options[k]),
                  ],
                ],
              ),
            ),
          ),
          if (_back) edge(right: false),
          if (_more) edge(right: true),
        ],
      ),
    );
  }
}

/// 목록 위의 정렬 줄: 정렬 종류를 고르는 선택 상자(select box)가 오른쪽에 있고, 왼쪽에는 [leading](예: 읽음 제외)을 둘 수 있다.
/// 흰 배경 띠가 화면(페이지 영역) 좌우 끝까지 퍼진다 (구분선은 없다).
class SortStrip extends StatelessWidget {
  const SortStrip({
    super.key,
    required this.options,
    this.leading,
    this.viewToggle,
  });

  final List<PadOption> options;

  /// 줄 왼쪽에 놓는 위젯 (예: 읽음 제외 토글).
  final Widget? leading;

  /// 정렬 선택 상자 왼쪽에 놓는 보기 방식 버튼 (리스트형 / 격자형).
  final Widget? viewToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // 정렬 줄의 배경: 라이트 모드는 흰색, 다크 모드는 카드 바탕색 (검색 필드와 같다).
    final fill = Theme.of(context).brightness == Brightness.dark
        ? palette.surface
        : Colors.white;
    final bleed = PageBleed.maybeOf(context);
    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: textGutter(context),
        vertical: 8,
      ),
      child: Row(
        children: [
          ?leading,
          const Spacer(),
          if (viewToggle != null) ...[viewToggle!, const SizedBox(width: 12)],
          _SortSelect(options: options),
        ],
      ),
    );
    return Padding(
      // 위(구분선)는 아래(목록)보다 더 넉넉히 띄운다.
      padding: const EdgeInsets.only(top: 14, bottom: 16),
      child: bleed == null
          // 페이지 틀 밖에서는 놓인 자리 너비 전체에 테두리 상자를 두른다.
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: palette.border),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: row,
            )
          // 페이지 틀 안에서는 배경 띠가 좌우 끝까지 퍼지고, 내용은 내용 너비 안에 놓인다.
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -bleed.extra,
                  right: -bleed.extra,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(color: fill),
                ),
                row,
              ],
            ),
    );
  }
}

/// 정렬 선택 상자: 고른 정렬 이름과 ▾가 테두리 상자에 들어 있고, 누르면 정렬 종류 목록이 열린다.
class _SortSelect extends StatelessWidget {
  const _SortSelect({required this.options});

  final List<PadOption> options;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final current = options.where((o) => o.selected).firstOrNull;
    return PopupMenuButton<int>(
      tooltip: '정렬',
      position: PopupMenuPosition.under,
      onSelected: (i) => options[i].onTap(),
      itemBuilder: (context) => [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Text(
              options[i].label,
              style: TextStyle(
                fontWeight: options[i].selected
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current?.label ?? '정렬',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(AppIcons.caretDown, size: 16, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 정렬 줄 아래 목록 · 격자의 바깥 배경: 정렬 줄과 한 덩어리로 느껴지도록 같은 흰색(다크 모드는 카드 바탕색) 띠가
/// 화면(페이지 영역) 좌우 끝까지 퍼지고 아래에 옅은 테두리선이 있다. 정렬 줄 아래 간격까지 같은 색으로 이어진다.
class SortBody extends StatelessWidget {
  const SortBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fill = Theme.of(context).brightness == Brightness.dark
        ? palette.surface
        : Colors.white;
    final extra = PageBleed.maybeOf(context)?.extra ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -extra,
          right: -extra,
          // 정렬 줄 아래 간격(16)까지 덮는다.
          top: -16,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
          ),
        ),
        // Ink 카드는 가장 가까운 Material 위에 그려지므로, 배경 띠 위에 새 Material을 깔아 카드가 띠에 가려지지 않게 한다.
        Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// 한 영역의 바깥 박스: 흰색(다크 모드는 카드 바탕색) 띠가 화면(페이지 영역) 좌우 끝까지 퍼지고 위아래에 옅은 테두리선이 있다.
/// 안쪽 내용은 내용 너비 안에 놓인다.
class BleedBox extends StatelessWidget {
  const BleedBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fill = Theme.of(context).brightness == Brightness.dark
        ? palette.surface
        : Colors.white;
    final extra = PageBleed.maybeOf(context)?.extra ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -extra,
          right: -extra,
          top: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: Border.symmetric(
                horizontal: BorderSide(color: palette.border),
              ),
            ),
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}
