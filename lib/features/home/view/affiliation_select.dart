import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/tab_access.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../view_model/affiliation_choice.dart';
import '../view_model/group_access_view_model.dart';

/// 기도 · 말씀 탭에서 지금 볼 소속. 소속 중 이 탭을 쓸 수 있는 소속 가운데 하나가 골라져 있다.
/// 교역자 이상이 "전체"를 골랐거나 선택지가 없으면 null.
Affiliation? chosenAffiliation(
  TabAccess access,
  AffiliationChoice choice,
  Member me,
) {
  final options = access.options;
  if (options.isEmpty || (me.isStaff && choice.isAll)) return null;
  return options.where((d) => d.id == choice.id).firstOrNull ?? options.first;
}

/// 위쪽 탭(서랍 버튼이 있는 줄) 오른쪽의 소속 선택: 테두리는 없지만 ▾로 눌러서 고르는 곳임을 알 수 있다.
/// 고를 수 있는 것이 둘 이상일 때만 고를 수 있고(교역자 이상은 "전체"가 더해진다), 하나뿐이면 이름만 보인다. 없으면 아무것도 보이지 않는다.
class AffiliationSelect extends StatelessWidget {
  const AffiliationSelect({
    super.key,
    required this.feature,
    required this.me,
    required this.choice,
  });

  final PageFeature feature;
  final Member me;
  final AffiliationChoice choice;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<GroupAccessViewModel>(
      key: ValueKey('select/${me.churchId}'),
      create: (context) => GroupAccessViewModel(
        AppScope.read(context).affiliations,
        me.churchId,
      ),
      builder: (context, vm) => StreamBuilder<List<Affiliation>>(
        stream: vm.affiliations,
        builder: (context, affs) {
          if (!affs.hasData) return const SizedBox.shrink();
          final access = TabAccess.of(feature, me, affs.data!);
          if (access.blocked || access.options.isEmpty) {
            return const SizedBox.shrink();
          }
          final current = chosenAffiliation(access, choice, me);
          final withAll = me.isStaff;
          final currentName = current?.name ?? '전체';
          final palette = context.palette;
          final style = TextStyle(color: palette.ink, fontSize: 15);
          if (access.options.length + (withAll ? 1 : 0) == 1) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(currentName, style: style),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current?.id ?? AffiliationChoice.all,
                isDense: true,
                style: style,
                icon: Icon(AppIcons.caretDown, color: palette.muted),
                borderRadius: BorderRadius.circular(AppRadius.card),
                items: [
                  if (withAll)
                    const DropdownMenuItem(
                      value: AffiliationChoice.all,
                      child: Text('전체'),
                    ),
                  for (final d in access.options)
                    DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: choice.select,
              ),
            ),
          );
        },
      ),
    );
  }
}
