import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/card_grid.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/site_header.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_request.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../settings/view/theme_mode_selector.dart';
import 'church_card.dart';
import 'church_request_dialog.dart';
import 'join_church_dialog.dart';

/// 일반 회원의 "내 교회" 화면: 상단 바 + [MyChurchesBody].
class MyChurchesPage extends StatelessWidget {
  const MyChurchesPage({
    super.key,
    required this.approved,
    required this.others,
    required this.requests,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required this.onOpen,
  });

  final List<Member> approved;
  final List<Member> others;
  final List<ChurchRequest> requests;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;
  final void Function(Member church, Department? department) onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(
            userName: userName,
            userEmail: userEmail,
            onSignOut: onSignOut,
            profileExtras: const ThemeModeSelector(),
          ),
          Expanded(
            child: MyChurchesBody(
              approved: approved,
              others: others,
              requests: requests,
              onOpen: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

/// 내가 속한 교회와 소속 부서. 속한 교회가 없으면 큰 안내 영역을 보여준다.
/// 앱 운영자의 "입장" 화면도 같은 내용을 쓴다.
class MyChurchesBody extends StatelessWidget {
  const MyChurchesBody({
    super.key,
    required this.approved,
    required this.others,
    required this.requests,
    required this.onOpen,
  });

  /// 승인되어 들어갈 수 있는 교회.
  final List<Member> approved;

  /// 승인 대기 중이거나 이용이 제한된 교회(입장 신청 현황).
  final List<Member> others;

  /// 내가 보낸 교회 생성 요청 중 아직 교회가 되지 않은 것(대기·거절).
  final List<ChurchRequest> requests;
  final void Function(Member church, Department? department) onOpen;

  @override
  Widget build(BuildContext context) {
    final hasChurch = approved.isNotEmpty;
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasChurch)
              _ChurchList(approved: approved, onOpen: onOpen)
            else
              const _NoChurchNotice(),
            const SizedBox(height: 24),
            _Actions(centered: !hasChurch),
            if (others.isNotEmpty || requests.isNotEmpty) ...[
              const SizedBox(height: 40),
              _ApplicationStatus(others: others, requests: requests),
            ],
          ],
        ),
      ),
    );
  }
}

/// 초대 코드 입장 / 교회 생성 요청 버튼. 교회가 없으면 안내 영역 아래에 가운데 정렬된다.
class _Actions extends StatelessWidget {
  const _Actions({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: () =>
              showAppDialog<void>(context, child: const JoinChurchDialog()),
          icon: const Icon(Icons.vpn_key_outlined, size: 18),
          label: const Text('초대 코드로 입장'),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              showAppDialog<void>(context, child: const ChurchRequestDialog()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('교회 생성 요청'),
        ),
      ],
    );
  }
}

class _ChurchList extends StatelessWidget {
  const _ChurchList({required this.approved, required this.onOpen});

  final List<Member> approved;
  final void Function(Member church, Department? department) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageTitle(title: '내 교회', subtitle: '들어갈 교회나 소속 부서를 선택하세요.'),
        CardGrid(
          minColumnWidth: 460,
          children: [
            for (final m in approved) ChurchCard(member: m, onOpen: onOpen),
          ],
        ),
      ],
    );
  }
}

/// 소속된 교회가 하나도 없을 때의 첫 화면.
class _NoChurchNotice extends StatelessWidget {
  const _NoChurchNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        constraints: const BoxConstraints(minHeight: 320),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.church_outlined, size: 64, color: context.palette.muted),
            const SizedBox(height: 24),
            Text(
              '소속된 교회가 없습니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '교회에서 받은 초대 코드로 입장하거나, 교회 생성을 요청해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// 입장 신청(승인 대기·이용 제한)과 교회 생성 요청(대기·거절) 현황.
class _ApplicationStatus extends StatelessWidget {
  const _ApplicationStatus({required this.others, required this.requests});

  final List<Member> others;
  final List<ChurchRequest> requests;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final r in requests)
        ListTile(
          leading: Icon(
            r.status == RequestStatus.pending
                ? Icons.hourglass_top
                : Icons.block,
            color: context.palette.muted,
          ),
          title: Text('${r.name} · 교회 생성 요청'),
          subtitle: Text(
            r.status == RequestStatus.pending
                ? '운영자 승인 대기 중'
                : '거절됨${r.rejectReason == null ? '' : ' · ${r.rejectReason}'}',
          ),
        ),
      for (final m in others)
        ListTile(
          leading: Icon(
            m.status == MemberStatus.pending
                ? Icons.hourglass_top
                : Icons.block,
            color: context.palette.muted,
          ),
          title: Text(m.churchName),
          subtitle: Text(
            m.status == MemberStatus.pending ? '입장 승인 대기 중' : '이용이 제한된 교회',
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('신청 현황', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
