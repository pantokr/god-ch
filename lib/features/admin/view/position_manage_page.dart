import '../../../core/widgets/app_loader.dart';

import '../../../core/layout/responsive.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/labeled_field.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/position_style.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/position.dart';
import '../../home/view/content_widgets.dart';
import '../../members/data/member_repository.dart';
import '../data/position_repository.dart';

/// 직급 관리 (교회 운영자): 직급을 만들고 고치고 지우며, 직급마다 권한을 정하고, 교인에게 직급을 준다.
/// 직급의 권한은 교인에게 복사되어 `firestore.rules`가 같은 기준으로 막는다.
/// 맨 위 "권한 목록"에 이 앱의 권한 전체와 직급으로 줄 수 있는지가 정리되어 있다.
class PositionManagePage extends StatelessWidget {
  const PositionManagePage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<_PositionsViewModel>(
      key: ValueKey('positions/${me.churchId}'),
      create: (context) => _PositionsViewModel(
        AppScope.read(context).positions,
        AppScope.read(context).members,
        me.churchId,
      ),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTitle(
                title: '직급 권한',
                action: FilledButton.icon(
                  onPressed: vm.busy ? null : () => _edit(context, vm),
                  icon: const Icon(AppIcons.plus, size: 18),
                  label: const Text('직급 만들기'),
                ),
              ),
              const _CatalogCard(),
              const SizedBox(height: 16),
              // 교인 목록은 한 번만 구독한다 (읽는 곳이 둘이어도 같은 값을 쓴다).
              StreamBuilder<List<Member>>(
                stream: vm.members,
                builder: (context, ms) {
                  final members = ms.data ?? const <Member>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 기본 직급: 교회 관리자 > 교역자 > 회원. 삭제할 수 없다.
                      _BuiltInSection(
                        me: me,
                        members: members,
                        onEdit: (b) => _editBuiltIn(context, vm, b),
                      ),
                      StreamBuilder<List<Position>>(
                        stream: vm.positions,
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return EmptyHint(
                              '불러오지 못했습니다${String.fromCharCode(10)}${snap.error}',
                            );
                          }
                          final items = snap.data;
                          if (items == null) {
                            return const Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(child: AppLoader()),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 기본 직급 "미배정": 직급을 받지 않은 인원. 지울 수 없다.
                              _UnassignedPositionCard(
                                count: [
                                  for (final m in members)
                                    if (m.isApproved &&
                                        m.role != Role.admin &&
                                        !m.isAppOperator &&
                                        m.isUnassigned)
                                      m,
                                ].length,
                              ),
                              for (final p in items)
                                _PositionCard(
                                  position: p,
                                  count: [
                                    for (final m in members)
                                      if (m.positionId == p.id) m,
                                  ].length,
                                  onEdit: () => _edit(context, vm, position: p),
                                  onDelete: () => _delete(context, vm, p),
                                  onMembers: () =>
                                      _members(context, vm, p, members),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              if (vm.error != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    textGutter(context),
                    12,
                    textGutter(context),
                    0,
                  ),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 기본 직급(교역자 · 회원)의 권한을 고친다. 이름은 고정이다.
  Future<void> _editBuiltIn(
    BuildContext context,
    _PositionsViewModel vm,
    BuiltInPosition b,
  ) async {
    final current = switch (b) {
      BuiltInPosition.staff => {
        for (final p in Permission.delegable)
          if (me.rolePermissions.staffHas(p)) p.key,
      },
      BuiltInPosition.member => {
        for (final p in Permission.delegable)
          if (me.rolePermissions.memberHas(p)) p.key,
      },
      BuiltInPosition.admin => <String>{},
    };
    final result = await showAppDialog<_PositionForm>(
      context,
      maxWidth: 480,
      child: _PositionFormView(
        builtIn: b,
        initialPermissions: current,
        initialStyle: me.rolePermissions.styleOf(b),
      ),
    );
    if (result == null) return;
    await vm.saveBuiltIn(
      b,
      result.permissions,
      icon: result.icon,
      color: result.color,
    );
  }

  Future<void> _edit(
    BuildContext context,
    _PositionsViewModel vm, {
    Position? position,
  }) async {
    final result = await showAppDialog<_PositionForm>(
      context,
      maxWidth: 480,
      child: _PositionFormView(initial: position),
    );
    if (result == null) return;
    if (position == null) {
      await vm.create(
        result.name,
        result.permissions,
        icon: result.icon,
        color: result.color,
      );
    } else {
      await vm.update(
        position,
        result.name,
        result.permissions,
        icon: result.icon,
        color: result.color,
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    _PositionsViewModel vm,
    Position p,
  ) async {
    final ok = await confirmChange(
      context,
      title: '직급 삭제',
      body: '"${p.name}" 직급을 삭제할까요? 이 직급을 가진 교인은 직급과 권한이 없어집니다.',
      confirmLabel: '삭제',
      danger: true,
    );
    if (ok) await vm.delete(p);
  }

  Future<void> _members(
    BuildContext context,
    _PositionsViewModel vm,
    Position p,
    List<Member> members,
  ) async {
    await showAppDialog<void>(
      context,
      maxWidth: 480,
      child: _MembersDialog(position: p, vm: vm),
    );
  }
}

/// 가진 권한을 묶음(인원 · 중보기도 · 말씀묵상 · 일정)별로 나눠 보여 준다.
/// 묶음마다 한 줄: 왼쪽에 묶음 이름, 오른쪽에 그 묶음의 권한 칩. 가진 것이 없는 묶음은 줄이 없다.
class _GroupedPermissions extends StatelessWidget {
  const _GroupedPermissions({required this.permissions});

  final List<Permission> permissions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final groups = [
      for (final g in PermissionGroup.values)
        if (g != PermissionGroup.fixed)
          (
            g,
            [
              for (final p in permissions)
                if (p.group == g) p,
            ],
          ),
    ].where((e) => e.$2.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) Divider(height: 16, color: palette.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    groups[i].$1.label,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in groups[i].$2)
                      Chip(
                        label: Text(p.label),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      textGutter(context),
      8,
      textGutter(context),
      10,
    ),
    child: Text(
      text,
      style: TextStyle(
        color: context.palette.muted,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
  );
}

/// 기본 직급 세 개를 위에서 아래로 높은 순서(교회 관리자 > 교역자 > 회원)로 보여 준다. 셋 다 삭제할 수 없다.
/// - 교회 관리자: 그 교회에서 모든 권한(절대 권한). 권한을 고칠 수 없다.
/// - 교역자 · 회원: 기본 권한을 보고 "수정"으로 권한을 정한다. 이름은 고정이다.
class _BuiltInSection extends StatelessWidget {
  const _BuiltInSection({
    required this.me,
    required this.members,
    required this.onEdit,
  });

  final Member me;
  final List<Member> members;
  final void Function(BuiltInPosition) onEdit;

  int _count(Role role) => [
    for (final m in members)
      if (m.isApproved && m.role == role && !m.isAppOperator) m,
  ].length;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    List<Permission> granted(BuiltInPosition b) => [
      for (final p in Permission.delegable)
        if (switch (b) {
          BuiltInPosition.admin => true,
          BuiltInPosition.staff => me.rolePermissions.staffHas(p),
          BuiltInPosition.member => me.rolePermissions.memberHas(p),
        })
          p,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('기본 직급 (교회 관리자 > 교역자 > 회원)'),
        for (final b in BuiltInPosition.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PositionStyle.iconOf(
                            me.rolePermissions.styleOf(b).icon,
                          ),
                          size: 20,
                          color: PositionStyle.colorOf(
                            me.rolePermissions.styleOf(b).color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${_count(Role.values.byName(b.id))}명',
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b == BuiltInPosition.admin
                          ? '${b.subtitle} · 이 교회의 모든 권한 · 삭제 불가'
                          : '${b.subtitle} · 삭제 불가',
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    if (b == BuiltInPosition.admin)
                      Text(
                        '모든 권한 (고정)',
                        style: TextStyle(
                          color: palette.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (granted(b).isEmpty)
                      Text('권한 없음', style: TextStyle(color: palette.muted))
                    else
                      _GroupedPermissions(permissions: granted(b)),
                    if (b != BuiltInPosition.admin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => onEdit(b),
                          child: const Text('수정'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 이 앱의 권한 전체: 묶음마다 권한과 줄 수 있는지 (현재 역할 기본값 + 직급으로 줄 수 있는 것).
class _CatalogCard extends StatelessWidget {
  const _CatalogCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text('권한 목록', style: Theme.of(context).textTheme.titleMedium),
        children: [
          for (final g in PermissionGroup.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                g.label,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final p in Permission.values.where((p) => p.group == g))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(p.label)),
                    const SizedBox(width: 8),
                    Text(
                      [
                        if (p.requires.isNotEmpty)
                          '필요: ${p.requires.map((r) => r.label).join(' · ')}',
                        if (p.staffDefault) '교역자 기본',
                        p.grantable ? '직급 부여' : '부여 불가',
                      ].join(' · '),
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// 직급 카드: 이름, 가진 권한, 인원 수. 버튼으로 인원 배정 · 수정 · 삭제.
class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.position,
    required this.count,
    required this.onEdit,
    required this.onDelete,
    required this.onMembers,
  });

  final Position position;
  final int count;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMembers;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final granted = position.granted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PositionStyle.iconOf(position.icon),
                    size: 20,
                    color: PositionStyle.colorOf(position.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      position.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '$count명',
                    style: TextStyle(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (granted.isEmpty)
                Text('권한 없음', style: TextStyle(color: palette.muted))
              else
                _GroupedPermissions(permissions: granted),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onMembers, child: const Text('인원')),
                  TextButton(onPressed: onEdit, child: const Text('수정')),
                  TextButton(
                    style: TrashIcon.textStyle(context),
                    onPressed: onDelete,
                    child: const Text('삭제'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기본 직급 "미배정" 카드: 직급을 받지 않은 인원의 수. 문서로 저장하지 않으므로 고치거나 지울 수 없다.
/// 이 인원의 권한은 역할(교역자 · 회원)의 기본 권한을 따른다.
class _UnassignedPositionCard extends StatelessWidget {
  const _UnassignedPositionCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Icon(AppIcons.shieldCheck, size: 20, color: palette.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Affiliation.unassignedName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(AppIcons.lock, size: 14, color: palette.muted),
              const SizedBox(width: 4),
              Text(
                '기본',
                style: TextStyle(color: palette.muted, fontSize: 12.5),
              ),
              const SizedBox(width: 12),
              Text(
                '$count명',
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 직급 만들기 · 수정에서 입력한 값.
class _PositionForm {
  const _PositionForm(
    this.name,
    this.permissions, {
    this.icon = PositionStyle.defaultIcon,
    this.color = PositionStyle.defaultColor,
  });

  final String name;
  final Set<String> permissions;
  final String icon;
  final int color;
}

class _PositionFormView extends StatefulWidget {
  const _PositionFormView({
    this.initial,
    this.builtIn,
    this.initialPermissions,
    this.initialStyle,
  });

  final Position? initial;

  /// 기본 직급을 고칠 때의 현재 아이콘과 색.
  final BuiltInStyle? initialStyle;

  /// 기본 직급(교역자 · 회원)을 고칠 때: 이름은 고정이고 권한만 정한다.
  final BuiltInPosition? builtIn;
  final Set<String>? initialPermissions;

  @override
  State<_PositionFormView> createState() => _PositionFormViewState();
}

class _PositionFormViewState extends State<_PositionFormView> {
  late final _name = TextEditingController(
    text: widget.builtIn?.name ?? widget.initial?.name,
  );
  late String _icon =
      widget.initial?.icon ??
      widget.initialStyle?.icon ??
      PositionStyle.defaultIcon;
  late int _color =
      widget.initial?.color ??
      widget.initialStyle?.color ??
      PositionStyle.defaultColor;
  late final Set<String> _selected = Permission.consistent({
    ...?widget.initialPermissions,
    ...?widget.initial?.permissions,
  });

  /// 권한 하나를 켜고 끈다. 끄면 그 권한이 선행인 권한도 함께 꺼진다 (켤 때는 선행 권한이 켜져 있어야 눌린다).
  void _toggle(Permission p, bool on) => setState(() {
    if (on) {
      _selected.add(p.key);
    } else {
      _selected.remove(p.key);
      for (final d in p.dependents) {
        _selected.remove(d.key);
      }
    }
  });

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.builtIn != null
              ? '${widget.builtIn!.name} 권한'
              : widget.initial == null
              ? '직급 만들기'
              : '직급 수정',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: '이름',
          child: TextField(
            controller: _name,
            autofocus: widget.builtIn == null,
            enabled: widget.builtIn == null,
            maxLength: Position.maxName,
            decoration: const InputDecoration(),
          ),
        ),
        // 직급에 붙는 아이콘과 색: 직급 카드와 회원 목록의 이름 옆에 보인다.
        if (widget.builtIn != BuiltInPosition.admin) ...[
          AppField.spacer,
          // 아이콘과 색은 버튼 둘로 줄였다: 누르면 고르는 창이 뜬다.
          LabeledField(
            label: '모양',
            child: Row(
              children: [
                _PickButton(
                  tooltip: '아이콘 고르기',
                  onTap: () async {
                    final v = await _pickIcon(context);
                    if (v != null) setState(() => _icon = v);
                  },
                  child: Icon(
                    PositionStyle.iconOf(_icon),
                    size: 22,
                    color: PositionStyle.colorOf(_color),
                  ),
                ),
                const SizedBox(width: 10),
                _PickButton(
                  tooltip: '색상 고르기',
                  onTap: () async {
                    final v = await _pickColor(context);
                    if (v != null) setState(() => _color = v);
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PositionStyle.colorOf(_color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        for (final g in PermissionGroup.values)
          if (Permission.delegable.any((p) => p.group == g)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 2),
              child: Text(
                g.label,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // 묶음 안은 조회 · 생성 · 삭제 · 관리로 나누어 보여준다.
            for (final k in PermissionKind.values)
              if (Permission.delegable.any(
                (p) => p.group == g && p.kind == k,
              )) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text(
                    k.label,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final p in Permission.delegable.where(
                  (p) => p.group == g && p.kind == k,
                ))
                  _PermissionTile(
                    permission: p,
                    checked: _selected.contains(p.key),
                    missing: [
                      for (final r in p.requires)
                        if (!_selected.contains(r.key)) r,
                    ],
                    onChanged: (v) => _toggle(p, v),
                  ),
              ],
          ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _PositionForm(
                  _name.text,
                  _selected,
                  icon: _icon,
                  color: _color,
                ),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 아이콘을 고르는 작은 창: 격자에서 하나를 누르면 그 키를 돌려주며 닫힌다.
Future<String?> _pickIcon(BuildContext context) => showDialog<String>(
  context: context,
  builder: (context) => Dialog(
    insetPadding: const EdgeInsets.all(24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('아이콘', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in PositionStyle.icons.entries)
                  _IconChoice(
                    icon: e.value,
                    color: context.palette.brand,
                    selected: false,
                    onTap: () => Navigator.pop(context, e.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);

/// 색을 고르는 팔레트 창: 색 하나를 누르면 그 값을 돌려주며 닫힌다.
Future<int?> _pickColor(BuildContext context) => showDialog<int>(
  context: context,
  builder: (context) => Dialog(
    insetPadding: const EdgeInsets.all(24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('색상', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final v in PositionStyle.colors)
                  _ColorChoice(
                    color: Color(v),
                    selected: false,
                    onTap: () => Navigator.pop(context, v),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);

/// 아이콘 · 팔레트 버튼: 지금 고른 모양을 담은 테두리 칸. 누르면 고르는 창이 뜬다.
class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: AppField.radius,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppField.radius,
            border: Border.all(color: context.palette.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 아이콘 고르기 칸 하나: 고른 아이콘은 고른 색의 옅은 면과 테두리로 보인다.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: AppField.radius,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : null,
          borderRadius: AppField.radius,
          border: Border.all(
            color: selected ? color : palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Icon(icon, size: 20, color: selected ? color : palette.muted),
      ),
    );
  }
}

/// 색 고르기 칸 하나: 고른 색은 바깥에 테두리 고리가 둘러진다.
class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: selected
              ? const Icon(AppIcons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// 권한 한 줄. 선행 권한이 없으면 눌리지 않고 "먼저 …"가 보이며, 선행 단계만큼 들여 써서 위아래 관계가 보인다.
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.permission,
    required this.checked,
    required this.missing,
    required this.onChanged,
  });

  final Permission permission;
  final bool checked;

  /// 아직 켜지지 않은 선행 권한들.
  final List<Permission> missing;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = missing.isEmpty;
    final tile = CheckboxListTile(
      value: checked,
      enabled: enabled,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(permission.label),
      subtitle: enabled
          ? null
          : Text(
              '먼저 ${missing.map((m) => m.label).join(' · ')}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
      onChanged: (v) => onChanged(v ?? false),
    );
    if (permission.depth == 0) return tile;
    // 아래 단계는 선행 단계 칸만큼 안으로 들어가고, 앞에 연결선(└)이 붙어 위 권한에 딸린 것임을 보인다.
    return Padding(
      padding: EdgeInsets.only(left: (permission.depth - 1) * 24.0 + 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 2),
            child: Text(
              '└',
              style: TextStyle(
                color: palette.muted.withValues(alpha: 0.7),
                fontSize: 16,
                height: 1.2,
              ),
            ),
          ),
          Expanded(child: tile),
        ],
      ),
    );
  }
}

/// 직급을 줄 교인 고르기: 승인된 교인 중 체크한 사람이 이 직급을 갖는다 (다른 직급은 바뀐다).
class _MembersDialog extends StatelessWidget {
  const _MembersDialog({required this.position, required this.vm});

  final Position position;
  final _PositionsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${position.name} 인원',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Member>>(
          stream: vm.members,
          builder: (context, snap) {
            final all = snap.data;
            if (all == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: AppLoader()),
              );
            }
            // 교회 관리자는 모든 권한이 있어 직급이 필요 없다.
            final list = [
              for (final m in all)
                if (m.isApproved && m.role != Role.admin && !m.isAppOperator) m,
            ];
            if (list.isEmpty) return const EmptyHint('인원 없음');
            return Column(
              children: [
                for (final m in list)
                  CheckboxListTile(
                    value: m.positionId == position.id,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(m.name),
                    subtitle:
                        m.positionId != null && m.positionId != position.id
                        ? Text('다른 직급', style: TextStyle(color: palette.muted))
                        : null,
                    onChanged: (v) =>
                        vm.assign(m, (v ?? false) ? position : null),
                  ),
              ],
            );
          },
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

class _PositionsViewModel extends ViewModel {
  _PositionsViewModel(this._repo, MemberRepository members, this.churchId)
    : positions = _repo.positions(churchId),
      members = members.members(churchId);

  final PositionRepository _repo;
  final String churchId;
  final Stream<List<Position>> positions;
  final Stream<List<Member>> members;

  Future<bool> create(
    String name,
    Set<String> permissions, {
    String icon = PositionStyle.defaultIcon,
    int color = PositionStyle.defaultColor,
  }) => run(
    () => _repo.create(
      churchId,
      name: name,
      permissions: permissions,
      icon: icon,
      color: color,
    ),
  );

  Future<bool> update(
    Position p,
    String name,
    Set<String> permissions, {
    String? icon,
    int? color,
  }) => run(
    () => _repo.update(
      churchId,
      p,
      name: name,
      permissions: permissions,
      icon: icon,
      color: color,
    ),
  );

  Future<bool> saveBuiltIn(
    BuiltInPosition b,
    Set<String> permissions, {
    String? icon,
    int? color,
  }) => run(
    () => _repo.saveBuiltIn(churchId, b, permissions, icon: icon, color: color),
  );

  Future<bool> delete(Position p) => run(() => _repo.delete(churchId, p));

  /// 교인에게 직급을 주거나 뺀다 ([position]이 null이면 뺀다).
  Future<bool> assign(Member m, Position? position) =>
      run(() => _repo.assign(churchId, m.id, position), blocking: false);
}
