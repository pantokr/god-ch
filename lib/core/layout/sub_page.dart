import '../icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'page_frame.dart';
import 'responsive.dart';

/// 상세·작성처럼 한 건을 보는 화면의 공통 틀: 가운데 영역.
/// 상단 바는 없다. 뒤로가기 버튼과 [actions]는 내용 맨 위(내용과 함께 스크롤)에 놓인다.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.child,
    required this.fallbackLocation,
    this.actions = const [],
    this.maxWidth = 760,
    this.inset = false,
    this.onBack,
    this.barTitle,
  });

  final String title;
  final Widget child;

  /// 이전 화면이 없을 때(주소로 바로 열었거나 새로고침한 뒤) 돌아갈 주소.
  final String fallbackLocation;
  final List<Widget> actions;
  final double maxWidth;

  /// 내용 전체가 좌우 여백 안에 놓이게 한다 (작성 화면들이 같은 카드 너비를 쓴다).
  final bool inset;

  /// 뒤로가기 동작. 없으면 이전 화면으로(없으면 [fallbackLocation]으로) 간다.
  final VoidCallback? onBack;

  /// 있으면 화면 맨 위에 상단 탭(뒤로가기 + 이 제목)을 두고, 내용 위의 뒤로가기 줄은 두지 않는다.
  final String? barTitle;

  void _back(BuildContext context) {
    if (onBack != null) return onBack!();
    context.canPop() ? context.pop() : context.go(fallbackLocation);
  }

  @override
  Widget build(BuildContext context) {
    final bar = barTitle;
    if (bar != null) return _withTopBar(context, bar);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: maxWidth,
            // 위쪽은 뒤로가기 버튼이 상단 가까이 오도록 좁게 둔다.
            verticalPadding: 4,
            inset: inset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: textGutter(context) > 8
                        ? textGutter(context) - 8
                        : 0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '돌아가기',
                        onPressed:
                            onBack ??
                            () => context.canPop()
                                ? context.pop()
                                : context.go(fallbackLocation),
                        icon: const Icon(AppIcons.arrowLeft),
                      ),
                      const Spacer(),
                      ...actions,
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 상단 탭이 있는 모양: 흰 바탕(다크 모드는 카드 바탕색)에 아래 테두리선, 뒤로가기와 제목이 거기에 있다.
  Widget _withTopBar(BuildContext context, String bar) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: dark ? palette.surface : Colors.white,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '돌아가기',
                      onPressed: () => _back(context),
                      icon: const Icon(AppIcons.arrowLeft),
                    ),
                    Expanded(
                      child: Text(
                        bar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: PageFrame(
                  maxWidth: maxWidth,
                  verticalPadding: 16,
                  inset: inset,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
