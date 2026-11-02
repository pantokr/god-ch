import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../home/view_model/affiliation_choice.dart';

/// 우리 소속의 위쪽 탭 오른쪽에 놓이는 소속 선택: 테두리 없이 이름과 ▾만 보이는 중보기도 탭의 소속 선택과 같은 모양.
/// 고를 수 있는 소속은 [sees]로 정한다 (교회 관리자는 모든 소속, 그 밖은 자기 소속). 하나뿐이면 이름만 보인다.
class PeopleAffiliationSelect extends StatefulWidget {
  const PeopleAffiliationSelect({
    super.key,
    required this.me,
    required this.choice,
  });

  final Member me;
  final AffiliationChoice choice;

  /// 고를 수 있는 소속들 (이름순). 화면과 선택이 같은 기준을 쓴다.
  static List<Affiliation> optionsOf(Member me, List<Affiliation> all) => [
    for (final a in all)
      if (me.sees(a)) a,
  ]..sort((a, b) => a.name.compareTo(b.name));

  /// 지금 보는 소속: 고른 소속이 선택지에 있으면 그것, 아니면 첫째.
  static Affiliation? currentOf(
    List<Affiliation> options,
    AffiliationChoice choice,
  ) {
    if (options.isEmpty) return null;
    return options.where((a) => a.id == choice.id).firstOrNull ?? options.first;
  }

  @override
  State<PeopleAffiliationSelect> createState() =>
      _PeopleAffiliationSelectState();
}

class _PeopleAffiliationSelectState extends State<PeopleAffiliationSelect> {
  // 스트림은 한 번만 만든다.
  late final Stream<List<Affiliation>> _affiliations = AppScope.read(context)
      .affiliations
      .affiliations(widget.me.churchId);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(
      color: palette.ink,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    return StreamBuilder<List<Affiliation>>(
      stream: _affiliations,
      builder: (context, snap) => ListenableBuilder(
        listenable: widget.choice,
        builder: (context, _) {
          final options = PeopleAffiliationSelect.optionsOf(
            widget.me,
            snap.data ?? const <Affiliation>[],
          );
          final current = PeopleAffiliationSelect.currentOf(
            options,
            widget.choice,
          );
          if (current == null) return const SizedBox.shrink();
          if (options.length == 1) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(current.name, style: style),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current.id,
                isDense: true,
                style: style,
                icon: Icon(AppIcons.caretDown, color: palette.muted),
                borderRadius: BorderRadius.circular(AppRadius.card),
                items: [
                  for (final a in options)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: widget.choice.select,
              ),
            ),
          );
        },
      ),
    );
  }
}
