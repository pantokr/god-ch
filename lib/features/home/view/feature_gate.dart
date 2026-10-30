import '../../../core/widgets/app_loader.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/member.dart';
import '../view_model/affiliation_choice.dart';
import '../view_model/group_access_view_model.dart';
import 'affiliation_select.dart';

/// 기도제목 · 성경 화면의 입구: 교역자가 소속별로 켜고 끈 기능([ChurchFeatures])을 확인한다.
/// - 속한 소속이 모두 꺼져 있으면 서비스가 허용되지 않았다는 안내만 보인다.
/// - 아니면 위쪽 탭에서 고른 소속([choice])을 [builder]에 넘긴다. 속한 소속이 없으면 null(교회 전체)이다.
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
    // 앱 개발자는 교회를 고칠 수 있어도 기도제목 내용은 볼 수 없다.
    if (me.isOperatorView && feature == PageFeature.prayer) {
      return const _Notice('앱 개발자는 기도제목을 볼 수 없습니다');
    }
    return ViewModelBuilder<GroupAccessViewModel>(
      key: ValueKey('access/${me.churchId}'),
      create: (context) => GroupAccessViewModel(
        AppScope.read(context).affiliations,
        me.churchId,
      ),
      builder: (context, vm) => StreamBuilder<List<Affiliation>>(
        stream: vm.affiliations,
        builder: (context, affs) => StreamBuilder<ChurchFeatures>(
          stream: vm.features,
          builder: (context, feat) {
            if (!affs.hasData || !feat.hasData) {
              return const Center(child: AppLoader());
            }
            final access = feat.data!.accessFor(feature, me, affs.data!);
            if (access.blocked) return _NotAllowed(feature: feature);
            return ListenableBuilder(
              listenable: choice,
              builder: (context, _) =>
                  builder(context, chosenAffiliation(access, choice)),
            );
          },
        ),
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
