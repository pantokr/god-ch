import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  });

  final String title;
  final Widget child;

  /// 이전 화면이 없을 때(주소로 바로 열었거나 새로고침한 뒤) 돌아갈 주소.
  final String fallbackLocation;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: maxWidth,
            verticalPadding: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Transform.translate(
                  offset: Offset(-(pad > 8 ? 8.0 : pad), 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '돌아가기',
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(fallbackLocation),
                        icon: const Icon(Icons.arrow_back),
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
}
