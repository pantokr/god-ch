import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/choice_row.dart';
import '../../../core/widgets/member_mark.dart';
import '../../../core/widgets/role_chips.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/person_card.dart';
import '../view_model/my_affiliations_view_model.dart';

/// 내 정보의 "내가 속한 교회": 교회마다 교회 · 직책 · 소속이 따로 줄을 이루고, 입장할 때 낸 정보가 그 아래에 구분되어 붙는다.
/// 교회도 소속도 여러 개일 수 있고, 속한 교회가 없으면(앱 개발자 등) 아무것도 보이지 않는다.
class MyAffiliationsCard extends StatelessWidget {
  const MyAffiliationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyAffiliationsViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MyAffiliationsViewModel(
          scope.churches,
          scope.affiliations,
          scope.people,
        );
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
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.church, color: context.palette.muted),
                        const SizedBox(width: 14),
                        const Text('내가 속한 교회', style: TextStyle()),
                      ],
                    ),
                    for (var i = 0; i < mine.length; i++) ...[
                      // 교회와 교회 사이는 구분선으로 뚜렷하게 나눈다.
                      SizedBox(height: i == 0 ? 20 : 16),
                      if (i > 0) ...[
                        Divider(height: 1, color: context.palette.border),
                        const SizedBox(height: 20),
                      ],
                      _Church(
                        member: mine[i],
                        affiliations: vm.affiliationsOf(mine[i].churchId),
                        card: vm.cardOf(mine[i].churchId, mine[i].id),
                        onBirthPublic: (v) =>
                            vm.setBirthPublic(mine[i].churchId, mine[i].id, v),
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

/// 교회 하나: 교회 · 직책 · 소속이 이름표 있는 줄로 넉넉히 떨어져 놓이고,
/// 입장할 때 이 교회에 제출한 정보는 구분선 아래에 따로 모인다.
class _Church extends StatelessWidget {
  const _Church({
    required this.member,
    required this.affiliations,
    required this.card,
    required this.onBirthPublic,
  });

  final Member member;
  final Stream<List<Affiliation>> affiliations;
  final Stream<PersonCard?> card;
  final ValueChanged<bool> onBirthPublic;

  String get _role => switch (member.role) {
    Role.admin => '교회 관리자',
    Role.staff => '교역자',
    Role.member => '교인',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasSubmitted =
        member.address.isNotEmpty || member.birthDate.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          '교회',
          Text(
            member.churchName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        _Line(
          '직책',
          Row(
            children: [
              MemberMark(role: member.role, size: 16),
              const SizedBox(width: 6),
              Text(_role, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Line(
          '소속',
          StreamBuilder<List<Affiliation>>(
            stream: affiliations,
            builder: (context, snap) {
              final names = [
                for (final d in snap.data ?? const <Affiliation>[])
                  if (member.affiliationIds.contains(d.id)) d.name,
              ];
              if (names.isEmpty) {
                return Text(
                  Affiliation.unassignedName,
                  style: TextStyle(color: palette.muted, fontSize: 14),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final n in names) AffiliationChip(n)],
              );
            },
          ),
        ),
        // 입장할 때 이 교회에 제출한 주소 · 생년월일 (교회별로 한 번만 내는 정보라 보기만 한다).
        if (hasSubmitted) ...[
          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 20),
          if (member.address.isNotEmpty) ...[
            _Line('주소', Text(member.address, style: _valueStyle)),
            const SizedBox(height: 16),
          ],
          if (member.birthDate.isNotEmpty) ...[
            _Line('생년월일', Text(member.birthDate, style: _valueStyle)),
            const SizedBox(height: 12),
            // 생일 공개: 끄면 본인과 교역자 이상에게만 보인다 (달력 · 사람 정보).
            StreamBuilder<PersonCard?>(
              stream: card,
              builder: (context, snap) => OnOffRow(
                label: '생일 공개',
                value: snap.data?.birthPublic ?? true,
                onChanged: onBirthPublic,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

const _valueStyle = TextStyle(fontSize: 14);

/// 이름표(왼쪽 칸)와 값이 한 줄을 이룬다. 칸 너비는 글씨 배율을 따라 이름표가 값에 맞닿지 않는다.
class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(64),
          child: Text(
            label,
            style: TextStyle(color: palette.muted, fontSize: 13),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }
}
