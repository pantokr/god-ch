import 'package:flutter/material.dart';

import '../../../core/widgets/settings_table.dart';

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
    // 묶음마다 표 하나 (직급 권한과 같은 모양): 설정 이름 · 켬 · 끔.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsTable(
          title: '공개 범위',
          rows: [
            SettingRow(
              label: '교역자 전용(비공개) 글 허용',
              value: s.allowPrivate,
              onChanged: (v) => onChanged(s.copyWith(allowPrivate: v)),
            ),
          ],
        ),
        SettingsTable(
          title: '공개',
          rows: [
            SettingRow(
              label: '조회수 공개',
              value: s.showViews,
              onChanged: (v) => onChanged(s.copyWith(showViews: v)),
            ),
            SettingRow(
              label: '글쓴이 공개',
              value: s.showAuthor,
              onChanged: (v) => onChanged(s.copyWith(showAuthor: v)),
            ),
          ],
        ),
        SettingsTable(
          title: '댓글',
          rows: [
            SettingRow(
              label: '댓글 허용',
              value: s.allowComments,
              onChanged: (v) => onChanged(s.copyWith(allowComments: v)),
            ),
          ],
        ),
        SettingsTable(
          title: '반응',
          rows: [
            SettingRow(
              label: '반응 허용',
              value: s.reactionsOn,
              // 켜면 이모티콘 전부, 끄면 모두 끈다.
              onChanged: (on) => onChanged(
                s.copyWith(
                  reactions: on
                      ? {for (final r in reactionTypes) r.id}
                      : const {},
                ),
              ),
            ),
            for (final r in reactionTypes)
              SettingRow(
                label: '${r.emoji} ${r.label}',
                value: s.reactions.contains(r.id),
                indent: true,
                onChanged: !s.reactionsOn
                    ? null
                    : (on) => onChanged(
                        s.copyWith(
                          reactions: on
                              ? {...s.reactions, r.id}
                              : {...s.reactions}.difference({r.id}),
                        ),
                      ),
              ),
            SettingRow(
              label: '이모티콘별 개수 표시',
              value: s.showCounts,
              indent: true,
              onChanged: s.reactionsOn
                  ? (v) => onChanged(s.copyWith(showCounts: v))
                  : null,
            ),
          ],
        ),
        SettingsTable(
          title: '삭제',
          rows: [
            SettingRow(
              label: '교역자 삭제 시 사유 필수',
              value: s.requireDeleteReason,
              onChanged: (v) => onChanged(s.copyWith(requireDeleteReason: v)),
            ),
          ],
        ),
        SettingsTable(
          title: '교역자',
          rows: [
            SettingRow(
              label: '비공개 글에 교역자 응답',
              value: s.privateResponses,
              onChanged: (v) => onChanged(s.copyWith(privateResponses: v)),
            ),
            SettingRow(
              label: '비공개 글 열람 기록',
              value: s.logPrivateAccess,
              onChanged: (v) => onChanged(s.copyWith(logPrivateAccess: v)),
            ),
          ],
        ),
      ],
    );
  }
}
