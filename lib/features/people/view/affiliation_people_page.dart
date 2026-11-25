import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import 'person_popup.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/member_mark.dart';
import '../../../core/widgets/stat_icons.dart' show Pastel;
import '../../../core/widgets/thumbnail_avatar.dart';
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
                      return _body(context, current, members, {
                        for (final a in affSnap.data!) a.id: a.name,
                      });
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
    Map<String, String> names,
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
            style: TextStyle(color: context.palette.muted),
          ),
        ),
        if (members.isEmpty)
          EmptyHint(_query.isEmpty ? '사람 없음' : '해당하는 사람 없음')
        else
          // 사람은 아바타 그리드로: 큰 사진 아래쪽에 이름 알약이 겹쳐 놓인다. 누르면 프로필 팝업이 뜬다.
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              // 늘 3열: 칸 너비에 맞춰 사진이 커진다 (넓은 화면에서도 너무 커지지 않게 상한을 둔다).
              child: LayoutBuilder(
                builder: (context, box) {
                  const columns = 3;
                  const gap = 16.0;
                  final tileWidth =
                      (box.maxWidth - gap * (columns - 1)) / columns;
                  final avatar = (tileWidth * 0.66).clamp(56.0, 104.0);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 28,
                      crossAxisSpacing: gap,
                      // 글씨가 커져도 이름 알약이 잘리지 않게 칸 높이가 글씨 배율을 따른다.
                      mainAxisExtent:
                          avatar + MediaQuery.textScalerOf(context).scale(14),
                    ),
                    itemCount: members.length,
                    itemBuilder: (context, i) => _PersonTile(
                      churchId: me.churchId,
                      person: members[i],
                      isMe: members[i].id == me.id,
                      avatar: avatar,
                    ),
                  );
                },
              ),
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

/// 아바타 그리드의 한 칸 (캐주얼): 사람마다 다른 파스텔 그라데이션 테두리의 큰 사진 아래쪽에
/// 이름 알약이 겹쳐 놓인다. 교회 관리자 · 교역자는 사진 위쪽 모서리에 직급 아이콘이 붙고,
/// 본인의 알약은 브랜드색으로 채워진다.
class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.churchId,
    required this.person,
    required this.isMe,
    required this.avatar,
  });

  final String churchId;
  final PersonCard person;
  final bool isMe;

  /// 테두리를 포함한 사진 지름 (칸 너비로 정해진다).
  final double avatar;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = person.name.isEmpty ? '이름 없음' : person.name;
    final i = Pastel.indexOf(person.id);
    final hue = Pastel.hue(i);
    final hue2 = Pastel.hue(i + 2);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => showPersonPopup(
        context,
        churchId: churchId,
        uid: person.id,
        name: person.name,
        photoUrl: person.photoUrl,
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: avatar,
            height: avatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 파스텔 그라데이션 테두리 + 면색 간격 + 사진.
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [hue, hue2],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.surface,
                    ),
                    child: ThumbnailAvatar(
                      name: person.name,
                      url: person.photoUrl,
                      radius: (avatar - 10) / 2,
                    ),
                  ),
                ),
                if (person.role != Role.member)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border),
                        boxShadow: AppShadow.soft(context),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: MemberMark(role: person.role, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 이름 알약: 사진 아래쪽에 걸쳐 겹친다.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isMe ? palette.brand : palette.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isMe ? palette.brand : hue.withValues(alpha: 0.6),
                  ),
                  boxShadow: AppShadow.soft(context),
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: isMe ? Colors.white : palette.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
