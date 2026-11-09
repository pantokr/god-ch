import '../../../core/widgets/app_loader.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/tab_access.dart';
import '../../../data/models/member.dart';
import '../view_model/affiliation_choice.dart';
import '../view_model/group_access_view_model.dart';
import 'affiliation_select.dart';

/// 중보기도 · 성경 화면의 입구: 미배정 교인을 가려낸다.
/// - 속한 소속이 없는 교인은 미배정 안내만 보인다.
/// - 아니면 위쪽 탭에서 고른 소속([choice])을 [builder]에 넘긴다. 속한 소속이 없거나 교역자가 "전체"를 고르면 null(교회 전체)이다.
class FeatureGate extends StatelessWidget {
  const FeatureGate({
    super.key,
    required this.feature,
    required this.me,
    required this.choice,
    required this.builder,
  });

  final PageFeature feature;
  final Member me;
  final AffiliationChoice choice;
  final Widget Function(BuildContext context, Affiliation? affiliation) builder;

  @override
  Widget build(BuildContext context) {
    // 앱 개발자는 교회를 고칠 수 있어도 중보기도 내용은 볼 수 없다.
    if (me.isOperatorView && feature == PageFeature.prayer) {
      return const _Notice('앱 개발자는 중보기도를 볼 수 없습니다');
    }
    return ViewModelBuilder<GroupAccessViewModel>(
      key: ValueKey('access/${me.churchId}'),
      create: (context) => GroupAccessViewModel(
        AppScope.read(context).affiliations,
        me.churchId,
      ),
      builder: (context, vm) => StreamBuilder<List<Affiliation>>(
        stream: vm.affiliations,
        builder: (context, affs) {
          if (!affs.hasData) return const Center(child: AppLoader());
          final access = TabAccess.of(feature, me, affs.data!);
          if (access.unassigned) return const _Notice('소속 미배정');
          if (access.blocked) return _NotAllowed(feature: feature);
          return ListenableBuilder(
            listenable: choice,
            builder: (context, _) =>
                builder(context, chosenAffiliation(access, choice, me)),
          );
        },
      ),
    );
  }
}

/// 속한 소속에서 이 기능이 꺼져 있을 때의 안내.
class _NotAllowed extends StatelessWidget {
  const _NotAllowed({required this.feature});

  final PageFeature feature;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.lock, size: 40, color: palette.muted),
            const SizedBox(height: 16),
            Text(
              '본 서비스가 허용되지 않았습니다',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '속한 소속에서 ${feature.label} 서비스를 사용할 수 없습니다.\n담당 교역자에게 문의해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.palette.muted),
      ),
    ),
  );
}
