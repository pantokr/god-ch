import 'package:flutter/material.dart';

import '../../../core/widgets/choice_row.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/panel_surface.dart';
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
    return PanelSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('운영 설정', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          // ---- 공개 범위 ----
          const _Group('공개 범위'),
          _Check(
            label: '교역자 전용(비공개) 글 허용',
            value: s.allowPrivate,
            onChanged: (v) => onChanged(s.copyWith(allowPrivate: v)),
          ),
          // ---- 공개 ----
          const _Group('공개'),
          _Check(
            label: '조회수 공개',
            value: s.showViews,
            onChanged: (v) => onChanged(s.copyWith(showViews: v)),
          ),
          _Check(
            label: '글쓴이 공개',
            value: s.showAuthor,
            onChanged: (v) => onChanged(s.copyWith(showAuthor: v)),
          ),
          // ---- 댓글 ----
          const _Group('댓글'),
          _Check(
            label: '댓글 허용',
            value: s.allowComments,
            onChanged: (v) => onChanged(s.copyWith(allowComments: v)),
          ),
          // ---- 반응: 허용한 이모티콘마다 세부 설정 ----
          const _Group('반응'),
          _Check(
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
            _Check(
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
          _Check(
            label: '이모티콘별 개수 표시',
            value: s.showCounts,
            indent: true,
            onChanged: s.reactionsOn
                ? (v) => onChanged(s.copyWith(showCounts: v))
                : null,
          ),
          // ---- 삭제 ----
          const _Group('삭제'),
          _Check(
            label: '교역자 삭제 시 사유 필수',
            value: s.requireDeleteReason,
            onChanged: (v) => onChanged(s.copyWith(requireDeleteReason: v)),
          ),
          // ---- 교역자 ----
          const _Group('교역자'),
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
    this.indent = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// 허용 항목에 딸린 세부 설정이면 안으로 들여 쓴다.
  final bool indent;

  @override
  Widget build(BuildContext context) => OnOffRow(
    label: label,
    value: value,
    onChanged: onChanged,
    indent: indent,
  );
}
