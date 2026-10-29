import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/list_style_toggle.dart';
import '../../../data/models/member.dart';
import '../../admin/view_model/pending_members_view_model.dart';
import '../../prayers/view/postit_card.dart';
import '../../notifications/view/notifications_button.dart';
import 'church_scope.dart';

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
  });

  final Member me;

  /// 지금 보고 있는 메뉴 (주소에서 읽는다).
  final ChurchSection section;

  final String userName;
  final VoidCallback onSignOut;
  final Widget child;

  static const _labels = {
    ChurchSection.prayer: '기도제목',
    ChurchSection.meetings: '모임',
    ChurchSection.bible: '성경',
    ChurchSection.mine: '내 활동',
    ChurchSection.prayerSettings: '기도 설정',
    ChurchSection.members: '교회 회원 관리',
    ChurchSection.join: '교회 입장 관리',
    ChurchSection.info: '교회 정보 관리',
  };

  static const _icons = {
    ChurchSection.prayer: (AppIcons.handHeart, AppIcons.handHeartFill),
    ChurchSection.meetings: (AppIcons.usersThree, AppIcons.usersThreeFill),
    ChurchSection.bible: (AppIcons.bookOpen, AppIcons.bookOpenFill),
    ChurchSection.mine: (AppIcons.user, AppIcons.userFill),
    ChurchSection.prayerSettings: (AppIcons.sliders, AppIcons.sliders),
    ChurchSection.members: (AppIcons.users, AppIcons.usersFill),
    ChurchSection.join: (AppIcons.key, AppIcons.keyFill),
    ChurchSection.info: (AppIcons.church, AppIcons.churchFill),
  };

  /// 교역자 이상에게 보이는 메뉴: 인원 · 입장 (조회와 교역자 업무).
  static const _staffOnly = [ChurchSection.members, ChurchSection.join];

  /// 교회 관리자에게만 보이는 메뉴: 앱을 고치는 일 (기도 설정 · 교회 정보).
  static const _adminOnly = [ChurchSection.prayerSettings, ChurchSection.info];

  /// 하단 탭의 이름 (서랍의 이름과 다르다): 모임 화면은 "일정"으로 부른다.
  static const _tabLabels = {
    ChurchSection.meetings: '일정',
    ChurchSection.prayer: '기도',
    ChurchSection.bible: '말씀',
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
    if ((_staffOnly.contains(section) && !me.isStaff) ||
        (_adminOnly.contains(section) && !me.isAdmin)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.home(me.churchId));
      });
    }

    // 목록 모양(알록달록 · 심플)은 기도제목 · 모임 · 성경이 함께 따르고, 위쪽 탭에서 바꾼다.
    final listStyle = AppScope.read(context).listStyle;
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
            section == ChurchSection.prayer &&
            listStyle.style == ListStyle.colorful;
        return SidebarScaffold(
          userName: userName,
          onProfile: () =>
              context.push(Routes.account, extra: profileDetailsOf(me)),
          onSignOut: onSignOut,
          backgroundColor: board ? prayerBoardColor(context) : null,
          // 무늬와 빛무리도 상단 바 뒤까지 한 장으로 깔아 배경이 끊기지 않게 한다.
          backdrop: board ? const PrayerBoardBackground() : null,
          // 위쪽 탭(서랍 버튼 줄) 오른쪽: 목록 모양(알록달록 · 심플)을 고른다.
          topBarTrailing: !hasList
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const ListStyleToggle()],
                ),
          railActions: [
            NotificationsButton(
              pendingRequests: pending,
              onOpenRequests: () => context.go(
                Routes.section(me.churchId, ChurchSection.members),
              ),
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
            if (me.isStaff)
              SidebarGroup(
                title: '관리',
                items: [
                  // 인원 관리가 관리 메뉴의 첫째다. 입장 요청이 있으면 오른쪽에 숫자가 나온다.
                  _item(context, ChurchSection.members, badge: pending),
                  _item(context, ChurchSection.join),
                  // 앱을 고치는 일은 교회 관리자만: 기도 설정 · 교회 정보.
                  if (me.isAdmin) _item(context, ChurchSection.prayerSettings),
                  if (me.isAdmin) _item(context, ChurchSection.info),
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
      child: me.isStaff
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: palette.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(AppIcons.church, size: 20, color: palette.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '내 교회 목록',
            icon: const Icon(AppIcons.caretUpDown, size: 20),
            onPressed: onSwitch,
          ),
        ],
      ),
    );
  }
}

/// 내 정보에 보여줄 교회 / 역할 항목.
List<ProfileDetail> profileDetailsOf(Member me) => [
  ProfileDetail('교회', me.churchName),
  ProfileDetail(
    '역할',
    me.isOperatorView
        ? '앱 개발자'
        : switch (me.role) {
            Role.admin => '교회 관리자',
            Role.staff => '교역자',
            Role.member => '교인',
          },
  ),
];
