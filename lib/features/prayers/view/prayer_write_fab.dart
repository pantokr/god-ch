import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer_settings.dart';
import '../view_model/prayer_write_view_model.dart';

/// 기도 화면 오른쪽 아래에 떠 있는 기도 요청 버튼. 기도제목을 쓴다.
/// 교회가 교역자만 쓰게 정했으면 교인에게는 보이지 않는다.
class PrayerWriteFab extends StatelessWidget {
  const PrayerWriteFab({super.key, required this.me});

  final Member me;

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
          // 앱 개발자는 기도제목을 쓰지 않는다.
          if (!canWrite || me.isOperatorView) return const SizedBox.shrink();
          return _WriteButton(
            onTap: () => context.push(Routes.newPrayer(me.churchId)),
          );
        },
      ),
    );
  }
}

/// 기본 플로팅 버튼 대신 앱의 네온 그라데이션으로 만든 기도 요청 버튼:
/// 약한 모서리의 직사각형에 빛 번짐 그림자, 펜 아이콘과 이름.
class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppDepth.brand(context),
        borderRadius: radius,
        boxShadow: AppDepth.glow(context, strength: 0.9),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.pencilSimple, size: 20, color: palette.onBrand),
                const SizedBox(width: 8),
                Text(
                  '기도 요청',
                  style: TextStyle(
                    color: palette.onBrand,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
