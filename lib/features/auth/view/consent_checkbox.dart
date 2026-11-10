import 'package:flutter/material.dart';

import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/theme.dart';

/// 개인정보 제3자 제공 동의 내용.
/// 초안이므로 서비스를 공개하기 전에 법률 검토를 받아 실제 운영 정책에 맞게 고쳐야 한다.
const thirdPartyConsentItems = <(String, String)>[
  ('제공받는 자', '회원이 입장을 신청하거나 소속된 교회의 교회 관리자·교역자'),
  ('제공 목적', '교인 확인, 입장 승인, 교회 내 연락 및 교인 관리'),
  ('제공 항목', '이름, 이메일, 전화번호, 주소·생년월일(입력한 경우)'),
  ('보유·이용 기간', '해당 교회에서 탈퇴하거나 회원 탈퇴 시까지'),
  ('동의 거부 권리', '동의를 거부할 수 있으나, 동의하지 않으면 가입할 수 없습니다.'),
];

/// 개인정보 제3자 제공 동의 상자: 핵심 내용을 바로 보여 주고, 상자 어디를 눌러도 동의가 바뀐다.
/// 전체 내용은 "전체 내용 보기"에서 읽고 바로 동의할 수 있다.
class ConsentCheckbox extends StatelessWidget {
  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// 상자에 바로 보여 줄 항목 (제공받는 자 · 제공 항목 · 보유·이용 기간).
  static const _summary = [0, 2, 3];

  Future<void> _showText(BuildContext context) async {
    final agreed = await showAppDialog<bool>(
      context,
      child: _ConsentText(agreed: value),
    );
    if (agreed == true) onChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.panel);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: value ? palette.brand.withValues(alpha: 0.06) : palette.surface,
        borderRadius: radius,
        border: Border.all(
          color: value ? palette.brand : palette.border,
          width: value ? 1.6 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      value ? AppIcons.checkCircleFill : AppIcons.checkCircle,
                      size: 26,
                      color: value ? palette.brand : palette.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '[필수] ',
                              style: TextStyle(color: palette.brand),
                            ),
                            const TextSpan(text: '개인정보 제3자 제공 동의'),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final i in _summary)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 38),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${thirdPartyConsentItems[i].$1}  ',
                            style: TextStyle(color: palette.muted),
                          ),
                          TextSpan(text: thirdPartyConsentItems[i].$2),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showText(context),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(AppIcons.caretRight, size: 16),
                    label: const Text('전체 내용 보기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 동의 내용: 항목마다 이름이 위, 내용이 아래에 놓여 좁은 화면과 큰 글씨에서도 읽힌다.
class _ConsentText extends StatelessWidget {
  const _ConsentText({required this.agreed});

  final bool agreed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DialogTitle('개인정보 제3자 제공 동의'),
        for (var i = 0; i < thirdPartyConsentItems.length; i++) ...[
          if (i > 0) Divider(height: 1, color: palette.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thirdPartyConsentItems[i].$1,
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  thirdPartyConsentItems[i].$2,
                  style: const TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ],
        DialogActions(
          top: 12,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('닫기'),
            ),
            if (!agreed)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('동의'),
              ),
          ],
        ),
      ],
    );
  }
}
