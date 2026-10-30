import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
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
                title: '직급 권한 관리',
                action: FilledButton.icon(
                  onPressed: vm.busy ? null : () => _edit(context, vm),
                  icon: const Icon(AppIcons.plus, size: 18),
                  label: const Text('직급 만들기'),
                ),
              ),
              const _CatalogCard(),
              const SizedBox(height: 16),
              // 기본 직급: 교회 관리자 > 교역자 > 회원. 삭제할 수 없다.
              StreamBuilder<List<Member>>(
                stream: vm.members,
                builder: (context, ms) => _BuiltInSection(
                  me: me,
                  members: ms.data ?? const <Member>[],
                  onEdit: (b) => _editBuiltIn(context, vm, b),
                ),
              ),
              const _SectionLabel('직급'),
              StreamBuilder<List<Position>>(
                stream: vm.positions,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return EmptyHint('불러오지 못했습니다\n${snap.error}');
                  }
                  final items = snap.data;
                  if (items == null) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    );
                  }
                  if (items.isEmpty) return const EmptyHint('직급 없음');
                  return StreamBuilder<List<Member>>(
                    stream: vm.members,
                    builder: (context, ms) {
                      final members = ms.data ?? const <Member>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                  );
                },
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
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
      child: _PositionFormView(builtIn: b, initialPermissions: current),
    );
    if (result == null) return;
    await vm.saveBuiltIn(b, result.permissions);
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
      await vm.create(result.name, result.permissions);
    } else {
      await vm.update(position, result.name, result.permissions);
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
    padding: const EdgeInsets.only(top: 8, bottom: 10),
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
                          b == BuiltInPosition.admin
                              ? AppIcons.crown
                              : AppIcons.shieldCheck,
                          size: 20,
                          color: palette.accent,
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
                  Icon(AppIcons.shieldCheck, size: 20, color: palette.accent),
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

/// 직급 만들기 · 수정에서 입력한 값.
class _PositionForm {
  const _PositionForm(this.name, this.permissions);

  final String name;
  final Set<String> permissions;
}

class _PositionFormView extends StatefulWidget {
  const _PositionFormView({
    this.initial,
    this.builtIn,
    this.initialPermissions,
  });

  final Position? initial;

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
        TextField(
          controller: _name,
          autofocus: widget.builtIn == null,
          enabled: widget.builtIn == null,
          maxLength: Position.maxName,
          decoration: const InputDecoration(labelText: '이름'),
        ),
        for (final g in PermissionGroup.values)
          if (Permission.delegable.any((p) => p.group == g)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(
                g.label,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final p in Permission.delegable.where((p) => p.group == g))
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
              onPressed: () =>
                  Navigator.pop(context, _PositionForm(_name.text, _selected)),
              child: const Text('저장'),
            ),
          ],
        ),
      ],
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
    return Padding(
      padding: EdgeInsets.only(left: permission.depth * 20.0),
      child: CheckboxListTile(
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

  Future<bool> create(String name, Set<String> permissions) =>
      run(() => _repo.create(churchId, name: name, permissions: permissions));

  Future<bool> update(Position p, String name, Set<String> permissions) => run(
    () => _repo.update(churchId, p, name: name, permissions: permissions),
  );

  Future<bool> saveBuiltIn(BuiltInPosition b, Set<String> permissions) =>
      run(() => _repo.saveBuiltIn(churchId, b, permissions));

  Future<bool> delete(Position p) => run(() => _repo.delete(churchId, p));

  /// 교인에게 직급을 주거나 뺀다 ([position]이 null이면 뺀다).
  Future<bool> assign(Member m, Position? position) =>
      run(() => _repo.assign(churchId, m.id, position), blocking: false);
}
