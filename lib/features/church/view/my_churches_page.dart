import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/card_grid.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/site_header.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import 'church_card.dart';
import 'create_church_dialog.dart';
import 'join_church_dialog.dart';

/// 내가 속한 교회와 소속 부서. 속한 교회가 없으면 큰 안내 영역을 보여준다.
class MyChurchesPage extends StatelessWidget {
  const MyChurchesPage({
    super.key,
    required this.approved,
    required this.others,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required this.onOpen,
  });

  /// 승인되어 들어갈 수 있는 교회.
  final List<Member> approved;

  /// 승인 대기 중이거나 이용이 제한된 교회.
  final List<Member> others;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;
  final void Function(Member church, Department? department) onOpen;

  @override
  Widget build(BuildContext context) {
    final hasChurch = approved.isNotEmpty;
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(
            userName: userName,
            userEmail: userEmail,
            onSignOut: onSignOut,
          ),
          Expanded(
            child: SingleChildScrollView(
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
                    if (others.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      _ApplicationStatus(others: others),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 초대 코드 입장 / 교회 생성 버튼. 교회가 없으면 안내 영역 아래에 가운데 정렬된다.
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
              showAppDialog<void>(context, child: const CreateChurchDialog()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('교회 생성하기'),
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
            const Icon(Icons.church_outlined, size: 64, color: AppColors.muted),
            const SizedBox(height: 24),
            Text(
              '소속된 교회가 없습니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '교회에서 받은 초대 코드로 입장하거나, 새 교회를 만들어 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// 승인 대기 중이거나 이용이 제한된 교회 목록.
class _ApplicationStatus extends StatelessWidget {
  const _ApplicationStatus({required this.others});

  final List<Member> others;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('신청 현황', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < others.length; i++) ...[
                if (i > 0) const Divider(),
                ListTile(
                  leading: Icon(
                    others[i].status == MemberStatus.pending
                        ? Icons.hourglass_top
                        : Icons.block,
                    color: AppColors.muted,
                  ),
                  title: Text(others[i].churchName),
                  subtitle: Text(
                    others[i].status == MemberStatus.pending
                        ? '승인 대기 중'
                        : '이용이 제한된 교회',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
