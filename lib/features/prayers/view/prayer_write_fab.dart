import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/widgets/create_fab.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer_settings.dart';
import '../view_model/prayer_write_view_model.dart';

/// 기도 화면 오른쪽 아래에 떠 있는 기도 요청 버튼. 고른 소속에 올릴 기도제목을 쓴다.
/// 교회가 교역자만 쓰게 정했으면 교인에게는 보이지 않는다.
class PrayerWriteFab extends StatelessWidget {
  const PrayerWriteFab({super.key, required this.me, this.affiliation});

  final Member me;

  /// 지금 고른 소속. 새 기도제목은 이 소속으로 올라간다.
  final Affiliation? affiliation;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PrayerWriteViewModel>(
      key: ValueKey('write/${me.churchId}'),
      create: (context) =>
          PrayerWriteViewModel(AppScope.read(context).prayers, me.churchId),
      builder: (context, vm) => StreamBuilder<PrayerSettings>(
        stream: vm.settings,
        initialData: PrayerSettings.standard,
        builder: (context, cfg) {
          final canWrite =
              (cfg.data ?? PrayerSettings.standard).writers ==
                  PrayerWriters.member ||
              me.isStaff;
          final allowed = canWrite && me.can(Permission.prayerWrite);
          // 앱 개발자는 기도제목을 쓰지 않는다.
          if (!allowed || me.isOperatorView) return const SizedBox.shrink();
          return CreateFab(
            label: '중보기도 요청',
            icon: AppIcons.pencilSimple,
            onTap: () => context.push(
              Routes.newPrayer(me.churchId, aff: affiliation?.id),
            ),
          );
        },
      ),
    );
  }
}
