import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../view_model/my_affiliations_view_model.dart';

/// 내 정보의 "소속": 내가 속한 교회들과 교회마다 내가 속한 소속들.
/// 교회도 소속도 여러 개일 수 있고, 속한 교회가 없으면(앱 개발자 등) 아무것도 보이지 않는다.
class MyAffiliationsCard extends StatelessWidget {
  const MyAffiliationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyAffiliationsViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MyAffiliationsViewModel(scope.churches, scope.affiliations);
      },
      builder: (context, vm) => StreamBuilder<List<Member>>(
        stream: vm.memberships,
        builder: (context, snap) {
          final mine = [
            for (final m in snap.data ?? const <Member>[])
              if (m.isApproved) m,
          ];
          if (mine.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.church, color: context.palette.muted),
                        const SizedBox(width: 14),
                        const Text(
                          '내가 속한 교회',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    for (final m in mine) ...[
                      const SizedBox(height: 16),
                      _Church(
                        member: m,
                        affiliations: vm.affiliationsOf(m.churchId),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 교회 하나: 이름과 역할, 그리고 내가 속한 소속들.
class _Church extends StatelessWidget {
  const _Church({required this.member, required this.affiliations});

  final Member member;
  final Stream<List<Affiliation>> affiliations;

  String get _role => switch (member.role) {
    Role.admin => '교회 관리자',
    Role.staff => '교역자',
    Role.member => '교인',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                member.churchName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_role, style: TextStyle(color: palette.muted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Affiliation>>(
          stream: affiliations,
          builder: (context, snap) {
            final names = [
              for (final d in snap.data ?? const <Affiliation>[])
                if (member.affiliationIds.contains(d.id)) d.name,
            ];
            if (names.isEmpty) {
              return Text('소속 없음', style: TextStyle(color: palette.muted));
            }
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in names)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      AppIcons.usersThree,
                      size: 16,
                      color: palette.muted,
                    ),
                    label: Text(n),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
