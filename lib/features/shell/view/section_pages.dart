import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../admin/view/affiliation_detail_page.dart';
import '../../admin/view/affiliation_manage_page.dart';
import '../../admin/view/church_info_manage_page.dart';
import '../../admin/view/church_join_tab.dart';
import '../../admin/view/church_members_tab.dart';
import '../../admin/view/position_manage_page.dart';
import '../../bible/view/bible_page.dart';
import '../../bible/view/devotion_settings_page.dart';
import '../../admin/view/membership_log_page.dart';
import '../../meetings/view/meeting_settings_page.dart';
import '../../home/view/my_activity_page.dart';
import '../../home/view/my_meetings_page.dart';
import '../../meetings/view/meetings_page.dart';
import '../../people/view/affiliation_people_page.dart';
import '../../people/view/calendar_page.dart';
import '../../prayers/view/prayer_board_page.dart';
import '../../prayers/view/prayer_settings_page.dart';
import 'church_scope.dart';

/// 교회 틀 안에 들어가는 메뉴별 페이지들. 필요한 정보는 [ChurchScope]에서 꺼낸다.

/// 기도제목.
class PrayerSectionPage extends StatelessWidget {
  const PrayerSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return PrayerBoardPage(me: scope.me, choice: scope.affiliationChoice);
  }
}

/// 모임: 노션에 정리한 모임 목록.
class MeetingsSectionPage extends StatelessWidget {
  const MeetingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      MeetingsPage(me: ChurchScope.of(context).me);
}

/// 성경: 말씀묵상.
class BibleSectionPage extends StatelessWidget {
  const BibleSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return BiblePage(me: scope.me, choice: scope.affiliationChoice);
  }
}

/// "내 활동": 내가 쓴 기도제목과 묵상.
class MineSectionPage extends StatelessWidget {
  const MineSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      MyActivityPage(me: ChurchScope.of(context).me);
}

/// 내 일정: 내 활동의 자세히 보기 (참여 예정 · 관심 · 완료).
class MyMeetingsSectionPage extends StatelessWidget {
  const MyMeetingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      MyMeetingsPage(me: ChurchScope.of(context).me);
}

/// 우리 소속: 내가 속한 소속의 사람들 (모든 교인).
class PeopleSectionPage extends StatelessWidget {
  const PeopleSectionPage({super.key});

  @override
  Widget build(BuildContext context) => AffiliationPeoplePage(
    me: ChurchScope.of(context).me,
    choice: ChurchScope.of(context).affiliationChoice,
  );
}

/// 달력: 모임 일정과 생일 (모든 교인).
class CalendarSectionPage extends StatelessWidget {
  const CalendarSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      CalendarPage(me: ChurchScope.of(context).me);
}

/// 직급 관리 (교회 운영자).
class PositionManageSectionPage extends StatelessWidget {
  const PositionManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      PositionManagePage(me: ChurchScope.of(context).me);
}

/// 입장 · 탈퇴 기록 (교회 운영자).
class MembershipLogSectionPage extends StatelessWidget {
  const MembershipLogSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      MembershipLogPage(me: ChurchScope.of(context).me);
}

/// 모임 일정 설정 (교회 운영자).
class MeetingSettingsSectionPage extends StatelessWidget {
  const MeetingSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      MeetingSettingsPage(me: ChurchScope.of(context).me);
}

/// 말씀묵상 설정 (교회 운영자).
class DevotionSettingsSectionPage extends StatelessWidget {
  const DevotionSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      DevotionSettingsPage(me: ChurchScope.of(context).me);
}

/// 중보기도 설정 (교회 운영자).
class PrayerSettingsSectionPage extends StatelessWidget {
  const PrayerSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      PrayerSettingsPage(me: ChurchScope.of(context).me);
}

class MemberManageSectionPage extends StatelessWidget {
  const MemberManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ChurchMembersTab(me: ChurchScope.of(context).me);
}

class JoinManageSectionPage extends StatelessWidget {
  const JoinManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ChurchJoinTab(me: ChurchScope.of(context).me);
}

class ChurchInfoSectionPage extends StatelessWidget {
  const ChurchInfoSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ChurchInfoManagePage(me: ChurchScope.of(context).me);
}

/// 소속 관리 (교역자 · 교회 운영자): 소속 목록.
class AffiliationManageSectionPage extends StatelessWidget {
  const AffiliationManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = ChurchScope.of(context).me;
    return AffiliationManagePage(
      me: me,
      onOpen: (a) => context.push(Routes.affiliation(me.churchId, a.id)),
    );
  }
}

class AffiliationDetailSectionPage extends StatelessWidget {
  const AffiliationDetailSectionPage({super.key, required this.affiliationId});

  final String affiliationId;

  @override
  Widget build(BuildContext context) => AffiliationDetailPage(
    me: ChurchScope.of(context).me,
    affiliationId: affiliationId,
  );
}
