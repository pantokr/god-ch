import 'package:flutter/material.dart';

import '../icons.dart';

/// 새로고침: 누를 때마다 [builder]에 넘기는 세대 번호가 올라간다.
/// 화면은 이 번호를 ViewModel의 key에 넣어, 목록 구독을 새로 만들게 한다.
class RefreshScope extends StatefulWidget {
  const RefreshScope({super.key, required this.builder});

  final Widget Function(BuildContext context, int generation, Widget button)
  builder;

  @override
  State<RefreshScope> createState() => _RefreshScopeState();
}

class _RefreshScopeState extends State<RefreshScope> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _generation,
    TextButton.icon(
      icon: const Icon(AppIcons.refresh, size: 18),
      label: const Text('새로고침'),
      onPressed: () => setState(() => _generation++),
    ),
  );
}
