import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/layout/site_header.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../admin/view/admin_page.dart';
import '../../prayers/view/feed_page.dart';
import '../../prayers/view/my_prayers_page.dart';
import '../../prayers/view/prayer_editor_page.dart';
import 'my_info_page.dart';

/// 교회(또는 부서) 안의 화면.
/// 넓은 화면에서는 상단 바의 메뉴로, 좁은 화면에서는 하단 탭으로 이동한다.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.me,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required this.onBack,
    this.department,
  });

  final Member me;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;

  /// null이면 교회 전체, 값이 있으면 그 부서 전용 공간.
  final Department? department;

  /// 내 교회 목록(메인 화면)으로 돌아간다.
  final VoidCallback onBack;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

/// 화면(탭) 종류. 메뉴 순서가 곧 이 순서다.
enum _Section { feed, mine, admin, info }

class _HomeShellState extends State<HomeShell> {
  _Section _current = _Section.feed;

  void _write() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PrayerEditorPage(
        me: widget.me,
        defaultDepartmentId: widget.department?.id,
      ),
    ),
  );

  /// 지금 화면 폭에서 보이는 메뉴. "내 정보"는 모바일 하단 탭에만 있다.
  List<_Section> _sections({required bool narrow}) => [
    _Section.feed,
    _Section.mine,
    if (widget.me.isStaff) _Section.admin,
    if (narrow) _Section.info,
  ];

  static const _labels = {
    _Section.feed: '기도제목',
    _Section.mine: '내 기도제목',
    _Section.admin: '교회 관리',
    _Section.info: '내 정보',
  };

  static const _icons = {
    _Section.feed: (Icons.favorite_border, Icons.favorite),
    _Section.mine: (Icons.person_outline, Icons.person),
    _Section.admin: (
      Icons.admin_panel_settings_outlined,
      Icons.admin_panel_settings,
    ),
    _Section.info: (Icons.account_circle_outlined, Icons.account_circle),
  };

  Widget _page(_Section section) => switch (section) {
    _Section.feed => FeedPage(
      me: widget.me,
      department: widget.department,
      onWrite: _write,
    ),
    _Section.mine => MyPrayersPage(me: widget.me, onWrite: _write),
    _Section.admin => AdminPage(me: widget.me),
    _Section.info => MyInfoPage(
      me: widget.me,
      userName: widget.userName,
      userEmail: widget.userEmail,
      onBack: widget.onBack,
      onSignOut: widget.onSignOut,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    final sections = _sections(narrow: narrow);
    // 화면 폭이 바뀌거나 교역자 권한이 회수되어 현재 메뉴가 사라지면 첫 화면으로.
    final current = sections.contains(_current) ? _current : sections.first;
    final dept = widget.department;

    return Scaffold(
      body: Column(
        children: [
          SiteHeader(
            userName: widget.userName,
            userEmail: widget.userEmail,
            onSignOut: widget.onSignOut,
            profileDetails: profileDetailsOf(widget.me),
            breadcrumb: [
              TextButton(onPressed: widget.onBack, child: const Text('내 교회')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  dept == null
                      ? widget.me.churchName
                      : '${widget.me.churchName} · ${dept.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            // 좁은 화면에서는 헤더에 메뉴를 그리지 않는다 (하단 탭이 대신한다).
            nav: [
              for (final s in sections)
                if (s != _Section.info)
                  NavItem(
                    label: _labels[s]!,
                    icon: _icons[s]!.$1,
                    selected: s == current,
                    onTap: () => setState(() => _current = s),
                  ),
            ],
          ),
          Expanded(child: _page(current)),
        ],
      ),
      bottomNavigationBar: narrow
          ? NavigationBar(
              selectedIndex: sections.indexOf(current),
              onDestinationSelected: (i) =>
                  setState(() => _current = sections[i]),
              destinations: [
                for (final s in sections)
                  NavigationDestination(
                    icon: Icon(_icons[s]!.$1),
                    selectedIcon: Icon(_icons[s]!.$2),
                    label: _labels[s]!,
                  ),
              ],
            )
          : null,
    );
  }
}
