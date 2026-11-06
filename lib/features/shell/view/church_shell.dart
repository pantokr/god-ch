import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../people/view/people_affiliation_select.dart';

import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/exit_guard.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../admin/view_model/pending_members_view_model.dart';
import '../../prayers/view/postit_card.dart';
import '../../../data/models/church_features.dart';
import '../../home/view/affiliation_select.dart';
import '../../home/view_model/affiliation_choice.dart';
import '../../notifications/view/notifications_button.dart';
import 'church_scope.dart';
import 'edge_bible_ad.dart';

/// 교회 안의 화면 틀: 왼쪽 메뉴(좁은 화면에서는 서랍) + 본문([child]) + 오른쪽 얇은 계정 띠.
/// 왼쪽 메뉴는 기도제목 · 모임 · 성경과 관리 메뉴다.
/// 메뉴를 바꾸면 주소가 바뀌므로 브라우저 뒤로가기로 이전 메뉴에 돌아갈 수 있다.
class ChurchShell extends StatelessWidget {
  const ChurchShell({
    super.key,
    required this.me,
    required this.section,
    required this.userName,
    required this.onSignOut,
    required this.child,
    required this.affiliationChoice,
  });

  final Member me;

  /// 지금 보고 있는 메뉴 (주소에서 읽는다).
  final ChurchSection section;

  final String userName;
  final VoidCallback onSignOut;
  final Widget child;

  /// 기도 · 성경 화면에서 지금 고른 소속.
  final AffiliationChoice affiliationChoice;

  static const _labels = {
    ChurchSection.prayer: '중보기도',
    ChurchSection.meetings: '모임 일정',
    ChurchSection.bible: '말씀묵상',
    ChurchSection.mine: '내 활동',
    ChurchSection.people: '우리 소속',
    ChurchSection.calendar: '달력',
    ChurchSection.myMeetings: '내 일정',
    ChurchSection.prayerSettings: '중보기도 설정',
    ChurchSection.devotionSettings: '말씀묵상 설정',
    ChurchSection.meetingSettings: '모임 일정 설정',
    ChurchSection.positions: '직급 권한',
    ChurchSection.members: '회원 관리',
    ChurchSection.join: '입장 관리',
    ChurchSection.info: '교회 정보',
    ChurchSection.memberLog: '입장 · 탈퇴 기록',
    ChurchSection.affiliations: '소속 관리',
  };

  static const _icons = {
    ChurchSection.prayer: (AppIcons.handHeart, AppIcons.handHeartFill),
    ChurchSection.meetings: (AppIcons.usersThree, AppIcons.usersThreeFill),
    ChurchSection.bible: (AppIcons.bookOpen, AppIcons.bookOpenFill),
    ChurchSection.mine: (AppIcons.user, AppIcons.userFill),
    ChurchSection.people: (AppIcons.users, AppIcons.usersFill),
    ChurchSection.calendar: (AppIcons.calendar, AppIcons.calendar),
    ChurchSection.myMeetings: (AppIcons.usersThree, AppIcons.usersThreeFill),
    ChurchSection.prayerSettings: (AppIcons.handHeart, AppIcons.handHeartFill),
    ChurchSection.devotionSettings: (AppIcons.bookOpen, AppIcons.bookOpenFill),
    ChurchSection.meetingSettings: (
      AppIcons.usersThree,
      AppIcons.usersThreeFill,
    ),
    ChurchSection.positions: (AppIcons.shieldCheck, AppIcons.shieldCheckFill),
    ChurchSection.members: (AppIcons.users, AppIcons.usersFill),
    ChurchSection.join: (AppIcons.key, AppIcons.keyFill),
    ChurchSection.info: (AppIcons.church, AppIcons.churchFill),
    ChurchSection.memberLog: (AppIcons.history, AppIcons.history),
    ChurchSection.affiliations: (AppIcons.usersThree, AppIcons.usersThreeFill),
  };

  /// 모든 교인에게 보이는 메뉴(서랍에서만 들어간다): 우리 소속 · 달력.
  static const _everyone = [ChurchSection.people, ChurchSection.calendar];

  /// 교역자 이상에게 보이는 메뉴: 인원 · 입장 · 소속 (조회와 교역자 업무).
  static const _staffOnly = [
    ChurchSection.members,
    ChurchSection.join,
    ChurchSection.affiliations,
  ];

  /// 교회 관리자에게만 보이는 메뉴: 앱을 고치는 일 (기도 설정 · 교회 정보).
  static const _adminOnly = [
    ChurchSection.prayerSettings,
    ChurchSection.devotionSettings,
    ChurchSection.meetingSettings,
    ChurchSection.positions,
    ChurchSection.info,
    ChurchSection.memberLog,
  ];

  /// 하단 탭의 이름 (서랍의 이름과 다르다): 모임 화면은 "일정"으로 부른다.
  static const _tabLabels = {
    ChurchSection.meetings: '모임 일정',
    ChurchSection.prayer: '중보기도',
    ChurchSection.bible: '말씀묵상',
    ChurchSection.mine: '내 활동',
  };

  /// 하단 탭 한 칸. 지금 보는 곳이 선택된다.
  SidebarItem _tab(BuildContext context, ChurchSection s) => SidebarItem(
    label: _tabLabels[s]!,
    icon: _icons[s]!.$1,
    selectedIcon: _icons[s]!.$2,
    selected: s == section,
    onTap: () => context.go(Routes.section(me.churchId, s)),
  );

  SidebarItem _item(BuildContext context, ChurchSection s, {int badge = 0}) =>
      SidebarItem(
        label: _labels[s]!,
        icon: _icons[s]!.$1,
        selectedIcon: _icons[s]!.$2,
        selected: s == section,
        onTap: () => context.go(Routes.section(me.churchId, s)),
        badge: badge,
      );

  @override
  Widget build(BuildContext context) {
    // 권한이 없는 메뉴 주소로 들어왔다면 첫 화면으로 보낸다 (예: 교인이 인원 관리 주소를 직접 열었을 때).
    if ((_staffOnly.contains(section) && !me.canManage) ||
        (_adminOnly.contains(section) && !me.isAdmin)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.home(me.churchId));
      });
    }

    // 목록 모양(알록달록 · 심플)은 기도제목 · 모임 · 성경이 함께 따르고, 위쪽 탭에서 바꾼다.
    final listStyle = AppScope.read(context).listStyle;
    // 서랍에서만 들어가는 메뉴(관리 · 기도 설정)에서는 하단 탭 대신 뒤로가기 버튼이 있다.
    final fromDrawer =
        _staffOnly.contains(section) ||
        _adminOnly.contains(section) ||
        _everyone.contains(section) ||
        section == ChurchSection.myMeetings;
    final hasList = const {
      ChurchSection.prayer,
      ChurchSection.meetings,
      ChurchSection.bible,
    }.contains(section);
    Widget frame(int pending) => ListenableBuilder(
      listenable: listStyle,
      builder: (context, _) {
        // 알록달록 기도제목은 상단 바까지 게시판 색 하나로 통일한다. 심플은 일반 배경이다.
        final board =
            kPostItEnabled &&
            section == ChurchSection.prayer &&
            listStyle.style == ListStyle.colorful;
        return SidebarScaffold(
          userName: userName,
          userPhotoUrl: me.photoUrl,
          onProfile: () => context.push(Routes.account),
          onSignOut: onSignOut,
          title: hasList || section == ChurchSection.mine
              ? _tabLabels[section]
              : _labels[section],
          onBack: fromDrawer
              ? () => ExitGuard.back(
                  context,
                  section == ChurchSection.myMeetings
                      ? Routes.section(me.churchId, ChurchSection.mine)
                      : Routes.home(me.churchId),
                )
              : null,
          backgroundColor: board ? prayerBoardColor(context) : null,
          // 무늬와 빛무리도 상단 바 뒤까지 한 장으로 깔아 배경이 끊기지 않게 한다.
          backdrop: board ? const PrayerBoardBackground() : null,
          // 위쪽 탭(서랍 버튼 줄) 오른쪽: 목록 모양(알록달록 · 심플)을 고른다.
          topBarTrailing: section == ChurchSection.people
              ? PeopleAffiliationSelect(me: me, choice: affiliationChoice)
              : !hasList
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (section == ChurchSection.prayer ||
                        section == ChurchSection.bible)
                      AffiliationSelect(
                        feature: section == ChurchSection.prayer
                            ? PageFeature.prayer
                            : PageFeature.word,
                        me: me,
                        choice: affiliationChoice,
                      ),
                    // 모임 일정: 모임 신청 알림을 바로 볼 수 있게 알림 버튼을 둔다.
                    if (section == ChurchSection.meetings)
                      NotificationsButton(
                        pendingRequests: pending,
                        churchId: me.churchId,
                      ),
                  ],
                ),
          railActions: [
            NotificationsButton(
              pendingRequests: pending,
              churchId: me.churchId,
            ),
          ],
          // 서랍 맨 위: 앱 이름에서 조금 띄워 "내가 속한 교회"를 보여준다.
          sidebarHeader: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    // 앱 개발자가 연 교회는 "내가 속한"이 아니다.
                    me.isOperatorView ? '교회' : '내가 속한 교회',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _ChurchCard(
                  name: me.churchName,
                  onSwitch: () => me.isOperatorView
                      ? context.go(Routes.adminChurches)
                      : context.push(Routes.churchList),
                ),
              ],
            ),
          ),
          // 하단 탭: 일정 · 기도 · 말씀 · 내 활동 (앱 개발자는 회원이 아니라 내 활동이 없다).
          tabs: [
            _tab(context, ChurchSection.meetings),
            _tab(context, ChurchSection.prayer),
            _tab(context, ChurchSection.bible),
            if (!me.isOperatorView) _tab(context, ChurchSection.mine),
          ],
          // 서랍: 교역자에게는 관리 메뉴가 있다.
          footer: const EdgeBibleAd(),
          groups: [
            // 앱 개발자에게는 앱 개발자 화면으로 돌아가는 길이 있다. 교회 탐색은 서랍이 아니라 "내가 속한 교회"의 교회 추가에 있다.
            if (me.isOperatorView)
              SidebarGroup(
                items: [
                  SidebarItem(
                    label: '앱 개발자 화면',
                    icon: AppIcons.shieldCheck,
                    selectedIcon: AppIcons.shieldCheckFill,
                    selected: false,
                    onTap: () => context.go(Routes.admin),
                  ),
                ],
              ),
            // 교회: 모든 교인이 보는 메뉴.
            SidebarGroup(
              title: '교회',
              items: [
                _item(context, ChurchSection.people),
                _item(context, ChurchSection.calendar),
              ],
            ),
            // 회원: 사람에 관한 일. 입장 요청이 있으면 회원 관리 오른쪽에 숫자가 나온다.
            if (me.canManage)
              SidebarGroup(
                title: '회원',
                items: [
                  _item(context, ChurchSection.members, badge: pending),
                  _item(context, ChurchSection.join),
                  _item(context, ChurchSection.affiliations),
                  if (me.isAdmin) _item(context, ChurchSection.positions),
                ],
              ),
            // 기능 설정: 하단 탭 순서(일정 · 중보기도 · 말씀묵상)와 같다. 교회 관리자만.
            if (me.isAdmin)
              SidebarGroup(
                title: '기능 설정',
                items: [
                  _item(context, ChurchSection.meetingSettings),
                  _item(context, ChurchSection.prayerSettings),
                  _item(context, ChurchSection.devotionSettings),
                ],
              ),
            // 교회: 교회 자체에 관한 일. 교회 관리자만.
            if (me.isAdmin)
              SidebarGroup(
                title: '교회',
                items: [
                  _item(context, ChurchSection.info),
                  _item(context, ChurchSection.memberLog),
                ],
              ),
          ],
          child: child,
        );
      },
    );

    return ChurchScope(
      me: me,
      userName: userName,
      onSignOut: onSignOut,
      affiliationChoice: affiliationChoice,
      child: me.canManage
          ? ViewModelBuilder<PendingMembersViewModel>(
              create: (context) => PendingMembersViewModel(
                AppScope.read(context).members,
                me.churchId,
              ),
              builder: (context, pvm) => StreamBuilder<int>(
                stream: pvm.count,
                initialData: 0,
                builder: (context, snap) => frame(snap.data ?? 0),
              ),
            )
          : frame(0),
    );
  }
}

/// 왼쪽 메뉴 위의 "지금 보는 교회" 카드와 교회 바꾸기 버튼.
class _ChurchCard extends StatelessWidget {
  const _ChurchCard({required this.name, required this.onSwitch});

  final String name;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    // 아이콘 · 교회 이름 · 오른쪽 화살표 어디를 눌러도 내 교회 목록이 열린다.
    return Semantics(
      button: true,
      label: '내 교회 목록',
      child: Material(
        color: palette.brand.withValues(alpha: 0.08),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onSwitch,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Icon(AppIcons.church, size: 20, color: palette.brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(AppIcons.caretUpDown, size: 20, color: palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
