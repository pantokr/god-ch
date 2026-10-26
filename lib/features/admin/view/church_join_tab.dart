import 'package:flutter/material.dart';

import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import 'invite_code_card.dart';

/// 교회 입장 관리: 입장 방식, 초대 코드(코드마다 역할 · 부서 · 필수 입력 정보 조건 · 유효기간).
class ChurchJoinTab extends StatelessWidget {
  const ChurchJoinTab({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.palette.muted);
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle(
              title: '교회 입장 관리',
              subtitle: '교회에 들어오는 방법과 조건을 정해요.',
            ),
            const SectionHeader(title: '입장 방식'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Point(
                      icon: Icons.vpn_key_outlined,
                      title: '초대 코드로만 입장',
                      body: '코드를 아는 회원만 입장을 신청할 수 있어요. 코드는 만든 날부터 7일 동안 유효해요.',
                    ),
                    const SizedBox(height: 14),
                    const _Point(
                      icon: Icons.how_to_reg_outlined,
                      title: '교역자 승인 필요',
                      body:
                          '신청한 회원은 승인 대기 상태로 들어오고, 교회 회원 관리에서 승인하면 이용할 수 있어요.',
                    ),
                    const SizedBox(height: 14),
                    const _Point(
                      icon: Icons.fact_check_outlined,
                      title: '필수 입력 정보 조건',
                      body:
                          '아래에서 코드를 만들 때 주소 · 생년월일을 필수로 고르면, 신청하는 회원은 입력해야 해요.',
                    ),
                    const SizedBox(height: 12),
                    Text('입장 방식은 지금 이 세 가지로 정해져 있어요.', style: muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            InviteCodeCard(me: me),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.palette.brand),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(body, style: TextStyle(color: context.palette.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
