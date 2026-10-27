import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'theme_mode_selector.dart';

/// 설정 대화상자: **앱 자체에 관한 것**만 있다 (화면 모드 · 앱 정보). 나에 관한 것(내 정보 · 비밀번호)은 프로필 창에 있다.
/// 왼쪽에 세로로 내려가는 탭, 오른쪽에 고른 탭의 설정.
Future<void> showSettingsDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
      child: const _SettingsPanel(),
    ),
  ),
);

enum _Tab {
  display('화면', Icons.palette_outlined),
  about('앱 정보', Icons.info_outline);

  const _Tab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel();

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  _Tab _tab = _Tab.display;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 왼쪽 세로 탭
        Container(
          width: narrow ? 64 : 180,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              palette.brand.withValues(alpha: 0.05),
              palette.surface,
            ),
            border: Border(right: BorderSide(color: palette.border)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!narrow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  child: Text(
                    '설정',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              for (final t in _Tab.values)
                _TabTile(
                  tab: t,
                  selected: t == _tab,
                  compact: narrow,
                  onTap: () => setState(() => _tab = t),
                ),
            ],
          ),
        ),
        // 저장 같은 버튼은 각 탭 안에 있으므로, 창을 닫는 버튼은 오른쪽 위 X 하나만 둔다.
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: switch (_tab) {
                  _Tab.display => const ThemeModeSelector(),
                  _Tab.about => const _AboutSetting(),
                },
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: '닫기',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabTile extends StatelessWidget {
  const _TabTile({
    required this.tab,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.onBrand : palette.ink;
    final radius = BorderRadius.circular(AppRadius.control);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: compact ? tab.label : '',
        child: Material(
          color: selected ? palette.brand : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (!compact) const SizedBox(width: 12),
                  Icon(tab.icon, size: 20, color: color),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutSetting extends StatelessWidget {
  const _AboutSetting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('같이', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '교회가 함께 말씀과 소식을 나누는 공간이에요.',
          style: TextStyle(color: context.palette.muted),
        ),
      ],
    );
  }
}
