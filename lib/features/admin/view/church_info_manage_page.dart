import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../data/models/church.dart';
import '../../../data/models/member.dart';
import '../../platform/view/church_info_form.dart';
import 'church_closure_card.dart';

/// 교회 정보 관리(교회 운영자): 이름 · 전화번호 · 주소 · 썸네일을 고치고, 맨 아래에서 폐쇄를 요청한다.
class ChurchInfoManagePage extends StatefulWidget {
  const ChurchInfoManagePage({super.key, required this.me});

  final Member me;

  @override
  State<ChurchInfoManagePage> createState() => _ChurchInfoManagePageState();
}

class _ChurchInfoManagePageState extends State<ChurchInfoManagePage> {
  // 스트림은 한 번만 만든다 (build마다 새로 만들면 다시 구독되어 깜빡인다).
  late final Stream<Church?> _church = AppScope.read(context).churchRegistry
      .church(widget.me.churchId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Church?>(
      stream: _church,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('불러오지 못했습니다\n${snap.error}'));
        }
        final church = snap.data;
        if (church == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ChurchInfoForm(
          // 저장 후 새 값으로 다시 그리지 않도록 교회 한 곳에는 같은 폼을 쓴다.
          key: ValueKey(church.id),
          church: church,
          title: '교회 정보 관리',
          footer: widget.me.isOperatorView
              ? null
              : ChurchClosureCard(me: widget.me),
        );
      },
    );
  }
}
