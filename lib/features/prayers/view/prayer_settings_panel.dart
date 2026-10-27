import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../../../data/models/reaction.dart';

/// 기도 요청 운영 설정: 라디오 · 체크 · 선택 박스로 교회가 어떻게 운영할지 정한다.
/// 기도 요청 페이지를 고칠 때 레이아웃 아래에 나온다. 바꾼 값은 페이지 "저장"과 함께 저장된다.
class PrayerSettingsPanel extends StatelessWidget {
  const PrayerSettingsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final PrayerSettings settings;
  final ValueChanged<PrayerSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('운영 설정', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          // ---- 작성 ----
          const _Group('작성'),
          RadioGroup<PrayerWriters>(
            groupValue: s.writers,
            onChanged: (v) {
              if (v != null) onChanged(s.copyWith(writers: v));
            },
            child: Column(
              children: [
                for (final w in PrayerWriters.values)
                  RadioListTile<PrayerWriters>(
                    value: w,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(w.label),
                  ),
              ],
            ),
          ),
          // ---- 공개 범위 ----
          const _Group('공개 범위'),
          _Check(
            label: '교역자 전용 비공개 허용',
            value: s.allowPrivate,
            onChanged: (v) => onChanged(s.copyWith(allowPrivate: v)),
          ),
          const SizedBox(height: 8),
          AppDropdown<PrayerVisibility>(
            label: '기본 공개 범위',
            value: s.allowPrivate
                ? s.defaultVisibility
                : PrayerVisibility.public,
            items: const [
              DropdownMenuItem(
                value: PrayerVisibility.public,
                child: Text('공개'),
              ),
              DropdownMenuItem(
                value: PrayerVisibility.private,
                child: Text('교역자 전용'),
              ),
            ],
            onChanged: s.allowPrivate
                ? (v) {
                    if (v != null) onChanged(s.copyWith(defaultVisibility: v));
                  }
                : null,
          ),
          // ---- 응원 ----
          const _Group('이모티콘 응원'),
          for (final r in reactionTypes)
            _Check(
              label: '${r.emoji} ${r.label}',
              value: s.reactions.contains(r.id),
              onChanged: (on) => onChanged(
                s.copyWith(
                  reactions: on
                      ? {...s.reactions, r.id}
                      : {...s.reactions}.difference({r.id}),
                ),
              ),
            ),
          _Check(
            label: '이모티콘별 개수 표시',
            value: s.showCounts,
            onChanged: s.reactionsOn
                ? (v) => onChanged(s.copyWith(showCounts: v))
                : null,
          ),
          // ---- 삭제 ----
          const _Group('삭제'),
          _Check(
            label: '교인 본인 글 삭제 허용',
            value: s.memberDelete,
            onChanged: (v) => onChanged(s.copyWith(memberDelete: v)),
          ),
          _Check(
            label: '교역자 삭제 시 사유 필수',
            value: s.requireDeleteReason,
            onChanged: (v) => onChanged(s.copyWith(requireDeleteReason: v)),
          ),
          // ---- 교역자 ----
          const _Group('교역자'),
          _Check(
            label: '공개 글에 교역자 댓글',
            value: s.staffComments,
            onChanged: (v) => onChanged(s.copyWith(staffComments: v)),
          ),
          _Check(
            label: '비공개 글에 교역자 응답',
            value: s.privateResponses,
            onChanged: (v) => onChanged(s.copyWith(privateResponses: v)),
          ),
          _Check(
            label: '비공개 글 열람 기록',
            value: s.logPrivateAccess,
            onChanged: (v) => onChanged(s.copyWith(logPrivateAccess: v)),
          ),
        ],
      ),
    );
  }
}

/// 설정 묶음 제목.
class _Group extends StatelessWidget {
  const _Group(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      title,
      style: TextStyle(
        color: context.palette.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Check extends StatelessWidget {
  const _Check({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: value,
    onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
    title: Text(label),
  );
}
