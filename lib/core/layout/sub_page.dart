import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'page_frame.dart';
import 'responsive.dart';

/// 상세·작성처럼 한 건을 보는 화면의 공통 틀: 상단 바 + 가운데 카드 영역.
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
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.palette.surface,
              border: Border(bottom: BorderSide(color: context.palette.border)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth + pad * 2),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad - 8),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(fallbackLocation),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('돌아가기'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ...actions,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: PageFrame(maxWidth: maxWidth, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
