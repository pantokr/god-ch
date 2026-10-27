import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';
import '../../../core/theme.dart';

/// 개인정보 제3자 제공 동의 내용.
/// 초안이므로 서비스를 공개하기 전에 법률 검토를 받아 실제 운영 정책에 맞게 고쳐야 한다.
const thirdPartyConsentItems = <(String, String)>[
  ('제공받는 자', '회원이 입장을 신청하거나 소속된 교회의 교회 관리자·교역자'),
  ('제공 목적', '교인 확인, 입장 승인, 교회 내 연락 및 교인 관리'),
  ('제공 항목', '이름, 이메일, 전화번호'),
  ('보유·이용 기간', '해당 교회에서 탈퇴하거나 회원 탈퇴 시까지'),
  ('동의 거부 권리', '동의를 거부할 수 있으나, 동의하지 않으면 가입할 수 없습니다.'),
];

/// "[필수] 개인정보 제3자 제공에 동의합니다" 체크박스와 내용 보기.
class ConsentCheckbox extends StatelessWidget {
  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: const Text('[필수] 개인정보 제3자 제공에 동의합니다'),
          ),
        ),
        TextButton(
          onPressed: () =>
              showAppDialog<void>(context, child: const _ConsentText()),
          child: const Text('내용 보기'),
        ),
      ],
    );
  }
}

class _ConsentText extends StatelessWidget {
  const _ConsentText();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('개인정보 제3자 제공 동의', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        for (final (label, value) in thirdPartyConsentItems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    label,
                    style: TextStyle(color: context.palette.muted),
                  ),
                ),
                Expanded(child: Text(value)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}
