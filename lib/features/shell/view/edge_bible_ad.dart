import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// 왼쪽 메뉴 맨 아래의 앱 광고: 같이와 말씀묵상이 연동되는 성경 앱 "엣지바이블" (같은 개발자가 만들었다).
/// 나중에 말씀묵상과 연동할 계획이다. 아직 공개된 설치 주소가 없어서 누르면 소개만 뜬다.
class EdgeBibleAd extends StatelessWidget {
  const EdgeBibleAd({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      shape: context.edgedCardShape,
      child: InkWell(
        customBorder: context.edgedCardShape,
        onTap: () => _showIntro(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: Image.asset(
                  'assets/images/edge_bible.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            '엣지바이블',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '광고',
                          style: TextStyle(color: palette.muted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '같이와 말씀묵상 연동되는 성경 앱',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIntro(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('엣지바이블'),
        content: const Text('같이와 말씀묵상이 연동되는 성경 앱입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
