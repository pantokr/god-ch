import 'package:flutter/material.dart';

import '../icons.dart';

/// 화면 맨 위에 붙는 "인터넷 연결 없음" 띠. [visible]이 true일 때만 높이를 차지한다.
/// 상태 표시줄 아래에 놓이고, 그 아래 화면은 [child]로 들어온다 (위쪽 여백은 띠가 이미 채웠으므로 없앤다).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: visible
              ? Material(
                  color: const Color(0xFF1F1F2B),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            AppIcons.wifiOff,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '인터넷 연결 없음',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          // 띠가 상태 표시줄 자리를 차지하는 동안 아래 화면은 위쪽 여백을 한 번 더 두지 않는다.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: visible,
            child: child,
          ),
        ),
      ],
    );
  }
}
