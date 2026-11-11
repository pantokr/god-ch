import 'package:flutter/material.dart';

import '../theme.dart';

/// 켬 · 끔 열의 너비 (직급 권한 표의 열과 같다).
const _col = 76.0;

/// 설정 한 묶음의 표: 윗줄에 묶음 이름과 열 이름(켬 · 끔), 아래에 설정 줄들이 가는 선으로 나뉘어 이어진다.
/// 직급 권한 화면의 표와 같은 모양이라, 기능 설정 화면들이 함께 같은 틀을 쓴다.
class SettingsTable extends StatelessWidget {
  const SettingsTable({
    super.key,
    required this.title,
    required this.rows,
    this.columns = const ['켬', '끔'],
  });

  final String title;
  final List<Widget> rows;

  /// 윗줄 오른쪽의 열 이름 (직급 권한 표는 전체 게시물 · 본인 게시물 / 허용).
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget head(String text) => SizedBox(
      width: _col,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 12.5),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: palette.ink.withValues(alpha: 0.05),
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 15)),
                    ),
                    for (final c in columns) head(c),
                  ],
                ),
              ),
              for (final row in rows) ...[
                Divider(height: 1, color: palette.border),
                row,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 설정 한 줄: 왼쪽에 설정 이름, 오른쪽 두 열에 켬 · 끔 라디오. [onChanged]가 null이면 눌리지 않고 줄이 흐려진다.
/// [indent]면 위 설정에 딸린 세부 설정으로 안으로 들여 쓴다.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.indent = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onChanged != null;
    Widget cell(bool v) => SizedBox(
      width: _col,
      child: Center(
        child: Radio<bool>(
          value: v,
          enabled: enabled,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
    return RadioGroup<bool>(
      groupValue: value,
      onChanged: (v) {
        if (v != null && onChanged != null) onChanged!(v);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(indent ? 32 : 16, 4, 8, 4),
        child: Row(
          children: [
            if (indent)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '└',
                  style: TextStyle(
                    color: palette.muted.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled
                        ? palette.ink
                        : palette.muted.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            cell(true),
            cell(false),
          ],
        ),
      ),
    );
  }
}
