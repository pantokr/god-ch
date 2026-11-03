import 'package:flutter/material.dart';

import 'person_popup.dart';

import '../../../core/layout/responsive.dart';
import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/person_card.dart';
import '../../home/view/content_widgets.dart';
import '../../home/view_model/affiliation_choice.dart';
import 'people_affiliation_select.dart';

/// 우리 소속: 내가 속한 소속의 사람들. 소속은 위쪽 탭 오른쪽에서 고르고(중보기도 탭과 같다),
/// 그 소속 사람들의 사진 · 이름 · 역할을 회원 관리처럼 검색 · 정렬(이름순 · 역할순)해서 보여준다.
/// 모든 교인이 볼 수 있고, 전화번호 같은 개인정보는 없다 ([PersonCard]).
/// 교회 관리자는 모든 소속을, 그 밖의 교인은 자기가 속한 소속만 고를 수 있다.
class AffiliationPeoplePage extends StatefulWidget {
  const AffiliationPeoplePage({
    super.key,
    required this.me,
    required this.choice,
  });

  final Member me;

  /// 위쪽 탭의 소속 선택이 담는 값 (중보기도 · 말씀묵상 탭과 함께 쓴다).
  final AffiliationChoice choice;

  @override
  State<AffiliationPeoplePage> createState() => _AffiliationPeoplePageState();
}

class _AffiliationPeoplePageState extends State<AffiliationPeoplePage> {
  late final Stream<List<Affiliation>> _affiliations = AppScope.read(context)
      .affiliations
      .affiliations(widget.me.churchId);
  late final Stream<List<PersonCard>> _people = AppScope.read(context).people
      .people(widget.me.churchId);

  String _query = '';

  static const _roleLabel = {
    Role.admin: '교회 관리자',
    Role.staff: '교역자',
    Role.member: '교인',
  };

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<List<Affiliation>>(
              stream: _affiliations,
              builder: (context, affSnap) => StreamBuilder<List<PersonCard>>(
                stream: _people,
                builder: (context, peopleSnap) {
                  if (affSnap.hasError || peopleSnap.hasError) {
                    return EmptyHint(
                      '불러오지 못했습니다${String.fromCharCode(10)}${affSnap.error ?? peopleSnap.error}',
                    );
                  }
                  if (!affSnap.hasData || !peopleSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    );
                  }
                  final options = PeopleAffiliationSelect.optionsOf(
                    me,
                    affSnap.data!,
                  );
                  if (options.isEmpty) return const EmptyHint('속한 소속 없음');
                  return ListenableBuilder(
                    listenable: widget.choice,
                    builder: (context, _) {
                      final current = PeopleAffiliationSelect.currentOf(
                        options,
                        widget.choice,
                      )!;
                      final q = _query.toLowerCase();
                      final members = [
                        for (final p in peopleSnap.data!)
                          if (p.isApproved &&
                              p.affiliationIds.contains(current.id) &&
                              (q.isEmpty || p.name.toLowerCase().contains(q)))
                            p,
                      ]..sort(_byRoleThenName);
                      return _body(context, current, members);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    Affiliation current,
    List<PersonCard> members,
  ) {
    final me = widget.me;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          inset: true,
          hint: '이름 검색',
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        // 검색 필드와 목록 사이는 아주 넉넉히 띄운다.
        const SizedBox(height: 64),
        Padding(
          padding: EdgeInsets.fromLTRB(
            textGutter(context),
            0,
            textGutter(context),
            24,
          ),
          child: Text(
            '${current.name} ${members.length}명',
            style: TextStyle(
              color: context.palette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (members.isEmpty)
          EmptyHint(_query.isEmpty ? '사람 없음' : '해당하는 사람 없음')
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _PersonRow(
                    churchId: widget.me.churchId,
                    person: members[i],
                    isMe: members[i].id == me.id,
                    roleLabel: _roleLabel[members[i].role]!,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// 교회 관리자 → 교역자 → 교인 순으로, 같으면 이름순.
int _byRoleThenName(PersonCard a, PersonCard b) {
  final r = b.role.index.compareTo(a.role.index);
  return r != 0 ? r : a.name.compareTo(b.name);
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.churchId,
    required this.person,
    required this.isMe,
    required this.roleLabel,
  });

  final String churchId;
  final PersonCard person;
  final bool isMe;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return ManageListRow(
      onTap: () => showPersonPopup(
        context,
        churchId: churchId,
        uid: person.id,
        name: person.name,
        photoUrl: person.photoUrl,
      ),
      leading: ManageListRow.avatar(
        context,
        person.name,
        imageUrl: person.photoUrl,
      ),
      title: person.name,
      // 교회 관리자는 이름 앞에 왕관으로 따로 표시한다.
      titleMark: switch (person.role) {
        Role.admin => const Tooltip(
          message: '교회 관리자',
          child: Icon(AppIcons.crown, size: 18, color: Color(0xFFE0A100)),
        ),
        Role.staff => Tooltip(
          message: '교역자',
          child: Icon(
            AppIcons.shieldCheck,
            size: 18,
            color: context.palette.brand,
          ),
        ),
        Role.member => null,
      },
      badge: isMe ? '본인' : null,
      line1: roleLabel,
    );
  }
}
