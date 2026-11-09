import 'dart:async';

import '../../../core/widgets/app_loader.dart';

import '../../../core/layout/responsive.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/settings_table.dart';

import '../../../core/widgets/labeled_field.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/position_style.dart';
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
          // 소속 관리와 같이 내용 전체가 좌우 여백 안에 놓인다.
          inset: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: vm.busy ? null : () => _edit(context, vm),
                  icon: const Icon(AppIcons.plus, size: 18),
                  label: const Text('직급 만들기'),
                ),
              ),
              const SizedBox(height: 16),
              // 소속 관리와 같은 카드 격자: 직급마다 카드 한 장 (아이콘 · 이름 · 인원 수), 오른쪽 위 연필로 수정 페이지가 열린다.
              ListenableBuilder(
                listenable: vm,
                builder: (context, _) {
                  final members = vm.latestMembers ?? const <Member>[];
                  int countOf(bool Function(Member) test) => [
                    for (final m in members)
                      if (test(m)) m,
                  ].length;
                  return StreamBuilder<List<String>>(
                    stream: vm.order,
                    builder: (context, orderSnap) =>
                        StreamBuilder<List<Position>>(
                          stream: vm.positions,
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return Text('불러오지 못했습니다\n${snap.error}');
                            }
                            final items = snap.data;
                            if (items == null) {
                              return const Center(child: AppLoader());
                            }
                            final byId = {for (final p in items) p.id: p};
                            // 정한 순서대로, 순서에 없는 직급(새로 만든 것)은 뒤에 붙는다.
                            final ids = _orderedIds(
                              orderSnap.data ?? const [],
                              items,
                            );
                            return ColumnWrap(
                              wide: 2,
                              narrow: 2,
                              children: [
                                for (var i = 0; i < ids.length; i++)
                                  _tile(
                                    context,
                                    vm,
                                    ids[i],
                                    byId[ids[i]],
                                    members,
                                    countOf,
                                    onUp: i == 0
                                        ? null
                                        : () => vm.move(ids, i, -1),
                                    onDown: i == ids.length - 1
                                        ? null
                                        : () => vm.move(ids, i, 1),
                                  ),
                              ],
                            );
                          },
                        ),
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

  /// 직급 수정은 대화상자가 아니라 별도 페이지에서 한다. 저장하면 입력한 값을, 취소하면 null을 돌려준다.
  Future<_PositionForm?> _openEditor(
    BuildContext context,
    Widget form, {
    Future<bool> Function()? onDelete,
  }) => Navigator.of(context, rootNavigator: true).push<_PositionForm>(
    MaterialPageRoute(
      builder: (context) => SubPage(
        title: '',
        barTitle: '',
        fallbackLocation: '',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          // 직접 만든 직급은 수정 페이지에서 지울 수 있다.
          if (onDelete != null)
            TextButton.icon(
              style: TrashIcon.textStyle(context),
              icon: const TrashIcon(),
              label: const Text('삭제'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (await onDelete()) navigator.pop();
              },
            ),
        ],
        // 카드 없이 기능 설정 화면처럼 표가 화면 너비를 채운다 (글 · 입력칸은 글 여백 안에 놓인다).
        child: form,
      ),
    ),
  );

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
    final result = await _openEditor(
      context,
      _PositionFormView(
        builtIn: b,
        initialPermissions: current,
        initialScopes: switch (b) {
          BuiltInPosition.staff => me.rolePermissions.staffScopes,
          BuiltInPosition.member => me.rolePermissions.memberScopes,
          BuiltInPosition.admin => null,
        },
        initialStyle: me.rolePermissions.styleOf(b),
        initialName: me.rolePermissions.nameOf(b),
      ),
      onDelete: () async {
        final ok = await confirmChange(
          context,
          title: '${me.rolePermissions.nameOf(b)} 삭제',
          body: '이름 · 모양 · 권한이 기본값으로 돌아갑니다. 이 직급의 인원은 그대로예요.',
          confirmLabel: '삭제',
          danger: true,
        );
        return ok && await vm.deleteBuiltIn(b);
      },
    );
    if (result == null) return;
    await vm.saveBuiltIn(
      b,
      result.permissions,
      scopes: result.scopes,
      name: result.name,
      icon: result.icon,
      color: result.color,
    );
  }

  Future<void> _edit(
    BuildContext context,
    _PositionsViewModel vm, {
    Position? position,
  }) async {
    final result = await _openEditor(
      context,
      _PositionFormView(initial: position),
      onDelete: position == null ? null : () => _delete(context, vm, position),
    );
    if (result == null) return;
    if (position == null) {
      await vm.create(
        result.name,
        result.permissions,
        scopes: result.scopes,
        icon: result.icon,
        color: result.color,
      );
    } else {
      await vm.update(
        position,
        result.name,
        result.permissions,
        scopes: result.scopes,
        icon: result.icon,
        color: result.color,
      );
    }
  }

  /// 직급을 지운다 (확인을 받는다). 지웠으면 true.
  Future<bool> _delete(
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
    return ok && await vm.delete(p);
  }

  /// 교회 관리자 인원을 고친다 (체크하면 관리자, 풀면 교인).
  Future<void> _roleMembers(BuildContext context, _PositionsViewModel vm) =>
      showAppDialog<void>(
        context,
        maxWidth: 480,
        child: _AdminMembersDialog(vm: vm, meId: me.id),
      );

  /// 카드 순서: 저장된 순서를 따르고, 없는 직급은 기본 순서(교회 관리자 · 교역자 · 회원 · 직접 만든 직급 이름순)로 뒤에 붙는다.
  static List<String> _orderedIds(List<String> saved, List<Position> items) {
    final all = [
      for (final b in BuiltInPosition.values) b.id,
      for (final p in items) p.id,
    ];
    return [
      for (final id in saved)
        if (all.contains(id)) id,
      for (final id in all)
        if (!saved.contains(id)) id,
    ];
  }

  Widget _tile(
    BuildContext context,
    _PositionsViewModel vm,
    String id,
    Position? p,
    List<Member> members,
    int Function(bool Function(Member)) countOf, {
    VoidCallback? onUp,
    VoidCallback? onDown,
  }) {
    if (p == null) {
      // 기본 직급: 교회 관리자 · 교역자 · 회원. 지울 수 없다 (교회 관리자는 모든 권한이라 고치지 않는다).
      final b = BuiltInPosition.values.firstWhere((b) => b.id == id);
      return _PositionTile(
        key: ValueKey('pos/$id'),
        icon: PositionStyle.iconOf(me.rolePermissions.styleOf(b).icon),
        color: PositionStyle.colorOf(me.rolePermissions.styleOf(b).color),
        name: me.rolePermissions.nameOf(b),
        caption: b == BuiltInPosition.admin ? '모든 권한' : '기본',
        count: countOf(
          (m) =>
              m.isApproved &&
              m.role == Role.values.byName(b.id) &&
              !m.isAppOperator,
        ),
        onEdit: b == BuiltInPosition.admin
            ? null
            : () => _editBuiltIn(context, vm, b),
        // 교회 관리자는 인원 버튼으로 누가 관리자인지 고친다.
        onMembers: b == BuiltInPosition.admin
            ? () => _roleMembers(context, vm)
            : null,
        onUp: onUp,
        onDown: onDown,
      );
    }
    return _PositionTile(
      key: ValueKey('pos/$id'),
      icon: PositionStyle.iconOf(p.icon),
      color: PositionStyle.colorOf(p.color),
      name: p.name,
      count: countOf((m) => m.positionId == p.id),
      onEdit: () => _edit(context, vm, position: p),
      onMembers: () => _members(context, vm, p, members),
      onUp: onUp,
      onDown: onDown,
    );
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

/// 직급 카드 (소속 카드와 같은 모양): 아이콘, 이름, 인원 수. 오른쪽 위 연필을 누르면 별도 수정 페이지가 열린다.
/// [onEdit]이 없으면(교회 관리자) 연필이 없다.
class _PositionTile extends StatelessWidget {
  const _PositionTile({
    super.key,
    this.onUp,
    this.onDown,
    required this.icon,
    required this.color,
    required this.name,
    required this.count,
    this.caption,
    this.onEdit,
    this.onMembers,
  });

  final IconData icon;
  final Color color;
  final String name;
  final int count;

  /// 이름 아래의 짧은 표시 (예: 기본).
  final String? caption;
  final VoidCallback? onEdit;

  /// 이 직급을 가진 교인을 고르는 창을 연다 (직접 만든 직급만).
  final VoidCallback? onMembers;

  /// 순서를 한 칸 앞 · 뒤로 옮긴다. 맨 앞(뒤)이면 null이라 눌리지 않는다.
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: AppShadow.soft(context),
      ),
      child: SizedBox(
        // 글씨가 커져도 넘치지 않게 글 영역만큼 높이가 따라 커진다.
        height: 156 + 60 * (MediaQuery.textScalerOf(context).scale(1) - 1),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 오른쪽 아래의 순서 버튼과 겹치지 않게 비워 두고, 좁으면 표시를 말줄임으로 줄인다.
                  Padding(
                    padding: const EdgeInsets.only(right: 58),
                    child: Row(
                      children: [
                        Text(
                          '$count명',
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                        if (caption != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              caption!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 순서: 카드 오른쪽 아래의 작은 앞 · 뒤 버튼.
            Positioned(
              bottom: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OrderButton(
                    tooltip: '앞으로',
                    icon: AppIcons.caretUp,
                    onPressed: onUp,
                  ),
                  _OrderButton(
                    tooltip: '뒤로',
                    icon: AppIcons.caretDown,
                    onPressed: onDown,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onMembers != null)
                    IconButton(
                      tooltip: '인원',
                      icon: const Icon(AppIcons.users, size: 20),
                      onPressed: onMembers,
                    ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: '수정',
                      icon: const Icon(AppIcons.pencilSimple, size: 20),
                      onPressed: onEdit,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카드 순서를 바꾸는 작은 버튼.
class _OrderButton extends StatelessWidget {
  const _OrderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    padding: EdgeInsets.zero,
  );
}

/// 직급 만들기 · 수정에서 입력한 값.
class _PositionForm {
  const _PositionForm(
    this.name,
    this.permissions, {
    this.scopes = const {},
    this.icon = PositionStyle.defaultIcon,
    this.color = PositionStyle.defaultColor,
  });

  final String name;

  /// 범위가 하나라도 있는(= 쓸 수 있는) 권한의 키들.
  final Set<String> permissions;

  /// 범위가 전체가 아닌 권한의 범위 (권한 키 → 소속 ID들 · `@mine`). 전체인 권한은 없다.
  final Map<String, Set<String>> scopes;
  final String icon;
  final int color;
}

class _PositionFormView extends StatefulWidget {
  const _PositionFormView({
    this.initial,
    this.builtIn,
    this.initialPermissions,
    this.initialScopes,
    this.initialStyle,
    this.initialName,
  });

  /// 기본 직급을 고칠 때의 현재 이름.
  final String? initialName;

  /// 기본 직급을 고칠 때의 현재 권한 범위.
  final Map<String, Set<String>>? initialScopes;

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
    text: widget.initialName ?? widget.builtIn?.name ?? widget.initial?.name,
  );
  late String _icon =
      widget.initial?.icon ??
      widget.initialStyle?.icon ??
      PositionStyle.defaultIcon;
  late int _color =
      widget.initial?.color ??
      widget.initialStyle?.color ??
      PositionStyle.defaultColor;

  /// 모든 직급에는 모든 권한이 있고, 권한마다 범위만 다르다: 권한 키 → 고른 범위
  /// (`*` = 전체, `@mine` = 내가 속한 소속, 그 밖에는 소속 ID). 아무것도 고르지 않으면 그 권한은 쓸 수 없다.
  /// 새 직급과 직접 만든 직급은 모든 권한이 "전체"로 시작한다 (예전에 없던 권한도 "전체"로 맞춘다).
  /// 교역자 · 회원 기본 직급은 지금 가진 권한 그대로다.
  late final Map<String, Set<String>> _scope = () {
    final granted = {
      ...?widget.initialPermissions,
      ...?widget.initial?.permissions,
    };
    final saved = widget.initial?.scopes ?? widget.initialScopes ?? const {};
    final builtIn = widget.builtIn != null;
    return <String, Set<String>>{
      for (final p in Permission.delegable)
        p.key: (!builtIn || p.inKeys(granted))
            // 범위는 전체 · 본인만 두 가지다 (본인만 = 본인이 쓴 것 · 만든 것만). 정한 적이 없는 교인 기본은 글 관리 · 반응 ·
            // 댓글 관리가 본인만이다.
            ? {
                (saved[p.key] ?? const <String>{}).contains(scopeMine) ||
                        (widget.builtIn == BuiltInPosition.member &&
                            widget.initialScopes == null &&
                            p.memberOwnOnly)
                    ? scopeMine
                    : '*',
              }
            : <String>{},
    };
  }();

  /// 쓸 수 있는 범위인가: 전체나 본인만이 골라져 있어야 한다.
  bool _usable(Set<String> v) => v.contains('*') || v.contains(scopeMine);

  /// 범위 체크박스 하나를 켜고 끈다. 전체와 본인만은 둘 중 하나만 고를 수 있고, 둘 다 풀면 그 권한은 쓸 수 없다.
  void _toggleScope(Permission p, String value, bool on) => setState(() {
    final set = _scope[p.key]!;
    set.clear();
    if (on) set.add(value);
  });

  /// 범위가 없는 권한(비공개 글 조회 · 일정 참여 · 인원 관리 · 소속 만들기 · 삭제)을 켜고 끈다.
  void _togglePlain(Permission p, bool on) => setState(() {
    final set = _scope[p.key]!;
    set.clear();
    if (on) set.add('*');
  });

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 표는 화면 너비를 채우고, 제목 · 입력칸 · 버튼은 글 여백 안에 놓인다 (기능 설정 화면과 같다).
    Widget gutter(Widget w) => Padding(
      padding: EdgeInsets.symmetric(horizontal: textGutter(context)),
      child: w,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 교역자 · 회원 직급 수정 페이지에는 제목이 없다 (이름 칸이 곧 이름이다).
        if (widget.builtIn == null) ...[
          gutter(
            Text(
              widget.initial == null ? '직급 만들기' : '직급 수정',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
        ],
        gutter(
          LabeledField(
            label: '이름',
            child: TextField(
              controller: _name,
              maxLength: Position.maxName,
              decoration: const InputDecoration(),
            ),
          ),
        ),
        // 직급에 붙는 아이콘과 색: 직급 카드와 회원 목록의 이름 옆에 보인다.
        if (widget.builtIn != BuiltInPosition.admin) ...[
          AppField.spacer,
          // 아이콘과 색은 버튼 둘로 줄였다: 누르면 고르는 창이 뜬다.
          gutter(
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
          ),
        ],
        const SizedBox(height: 18),
        // 묶음(중보기도 · 말씀묵상 · 일정 · …)마다 표: 범위가 뜻 있는 권한은 전체 · 본인만 열, 나머지 권한은 허용 열 하나다.
        for (final g in PermissionGroup.values)
          if (Permission.delegable.any((p) => p.group == g)) ...[
            if (Permission.delegable.any((p) => p.group == g && p.scoped))
              SettingsTable(
                title: g.label,
                columns: const ['전체 게시물', '본인 게시물'],
                rows: [
                  for (final p in Permission.delegable.where(
                    (p) => p.group == g && p.scoped,
                  ))
                    _ScopeRow(
                      permission: p,
                      scoped: true,
                      selected: _scope[p.key]!,
                      onToggle: (value, on) => _toggleScope(p, value, on),
                    ),
                ],
              ),
            if (Permission.delegable.any((p) => p.group == g && !p.scoped))
              SettingsTable(
                // 범위 있는 권한과 한 묶음에 있으면 제목을 달리한다 (예: 중보기도 조회).
                title: Permission.delegable.any((p) => p.group == g && p.scoped)
                    ? '${g.label} 조회'
                    : g.label,
                columns: const ['허용'],
                rows: [
                  for (final p in Permission.delegable.where(
                    (p) => p.group == g && !p.scoped,
                  ))
                    _ScopeRow(
                      permission: p,
                      scoped: false,
                      selected: _scope[p.key]!,
                      onToggle: (value, on) => _togglePlain(p, on),
                    ),
                ],
              ),
          ],
        const SizedBox(height: 12),
        gutter(
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
                    {
                      for (final e in _scope.entries)
                        if (_usable(e.value)) e.key,
                    },
                    scopes: {
                      for (final e in _scope.entries)
                        if (e.value.contains(scopeMine)) e.key: {scopeMine},
                    },
                    icon: _icon,
                    color: _color,
                  ),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 아이콘을 고르는 작은 창: 격자에서 하나를 누르면 그 키를 돌려주며 닫힌다.
Future<String?> _pickIcon(BuildContext context) => showAppDialog<String>(
  context,
  maxWidth: 360,
  child: Builder(
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DialogTitle('아이콘'),
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
);

/// 색을 고르는 팔레트 창: 색 하나를 누르면 그 값을 돌려주며 닫힌다.
Future<int?> _pickColor(BuildContext context) => showAppDialog<int>(
  context,
  maxWidth: 360,
  child: Builder(
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DialogTitle('색상'),
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

/// 권한 범위 표의 열 너비 (전체 · 본인만).
const _scopeCol = 76.0;

/// 권한 한 줄: 왼쪽에 권한 이름, 오른쪽 두 열에 체크 칸 (전체 · 본인만). 둘 다 비우면 쓸 수 없는 권한이라 줄이 흐려진다.
/// 글 관리 권한은 아래에 "비공개 글도 보기" 체크가 더 있다.
class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.permission,
    required this.selected,
    required this.onToggle,
    required this.scoped,
  });

  final Permission permission;
  final Set<String> selected;
  final void Function(String value, bool on) onToggle;

  /// 범위(전체 · 본인만)가 있는 권한인가. 아니면 허용 칸 하나다.
  final bool scoped;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final usable = selected.contains('*') || selected.contains(scopeMine);
    Widget cell(String value) => SizedBox(
      width: _scopeCol,
      child: Center(
        child: Checkbox(
          value: selected.contains(value),
          onChanged: (v) => onToggle(value, v ?? false),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: usable ? palette.ink : palette.muted,
                        ),
                      ),
                      if (permission.hint.isNotEmpty)
                        Text(
                          permission.hint,
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                    ],
                  ),
                ),
              ),
              if (scoped) ...[cell('*'), cell(scopeMine)] else cell('*'),
            ],
          ),
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
        ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final all = vm.latestMembers;
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

/// 교회 관리자 인원: 체크하면 관리자가 되고 풀면 교인이 된다. 본인은 풀 수 없고, 마지막 관리자도 풀 수 없다.
class _AdminMembersDialog extends StatelessWidget {
  const _AdminMembersDialog({required this.vm, required this.meId});

  final _PositionsViewModel vm;
  final String meId;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DialogTitle('교회 관리자 인원', gap: 12),
        ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final all = vm.latestMembers;
            if (all == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: AppLoader()),
              );
            }
            final list = [
              for (final m in all)
                if (m.isApproved && !m.isAppOperator) m,
            ]..sort((a, b) => a.name.compareTo(b.name));
            final admins = list.where((m) => m.role == Role.admin).length;
            if (list.isEmpty) return const EmptyHint('인원 없음');
            return Column(
              children: [
                for (final m in list)
                  CheckboxListTile(
                    value: m.role == Role.admin,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(m.name),
                    subtitle: m.id == meId
                        ? Text('본인', style: TextStyle(color: palette.muted))
                        : null,
                    // 본인과 마지막 관리자는 풀 수 없다 (관리자가 없어지지 않게).
                    onChanged:
                        m.role == Role.admin && (m.id == meId || admins <= 1)
                        ? null
                        : (v) => vm.setRole(
                            m,
                            (v ?? false) ? Role.admin : Role.member,
                          ),
                  ),
              ],
            );
          },
        ),
        DialogActions(
          children: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PositionsViewModel extends ViewModel {
  _PositionsViewModel(this._repo, MemberRepository members, this.churchId)
    : _memberRepo = members,
      // 정렬 맞추기와 화면이 함께 읽으므로 여러 번 구독할 수 있게 한다.
      positions = _repo.positions(churchId).asBroadcastStream(),
      order = _repo.order(churchId).asBroadcastStream() {
    // 교인 목록은 한 번만 구독해 두고 화면 · 대화상자가 함께 읽는다 (교인 스트림은 한 번만 구독할 수 있다).
    _membersSub = members.members(churchId).listen((v) {
      latestMembers = v;
      notifyListeners();
    }, onError: (_) {});
    // 모든 직급에는 모든 권한이 있다: 예전에 만든 직급에 없던 권한을 "전체" 범위로 채운다 (한 번만).
    _alignSub = positions.listen((list) {
      for (final p in list) {
        if (_aligned.add(p.id) &&
            Permission.delegable.any((d) => !p.permissions.contains(d.key))) {
          // 맞추기가 실패해도(권한 · 네트워크) 화면은 그대로 보인다.
          Future(
            () => _repo.update(
              churchId,
              p,
              name: p.name,
              permissions: {for (final d in Permission.delegable) d.key},
              scopes: p.scopes,
            ),
          ).catchError((Object _) {});
        }
      }
    });
  }

  final _aligned = <String>{};
  late final StreamSubscription<List<Position>> _alignSub;
  late final StreamSubscription<List<Member>> _membersSub;

  /// 가장 최근에 읽은 교인 목록. 아직 못 읽었으면 null.
  List<Member>? latestMembers;

  @override
  void dispose() {
    _alignSub.cancel();
    _membersSub.cancel();
    super.dispose();
  }

  final PositionRepository _repo;
  final MemberRepository _memberRepo;
  final String churchId;
  final Stream<List<Position>> positions;

  /// 저장된 카드 순서 (직급 ID들).
  final Stream<List<String>> order;

  /// [ids]의 [index]번째 카드를 [delta]칸(-1 앞 · 1 뒤) 옮기고 순서를 저장한다.
  Future<bool> move(List<String> ids, int index, int delta) {
    final to = index + delta;
    if (to < 0 || to >= ids.length) return Future.value(true);
    final next = [...ids];
    final item = next.removeAt(index);
    next.insert(to, item);
    return run(() => _repo.saveOrder(churchId, next));
  }

  Future<bool> create(
    String name,
    Set<String> permissions, {
    Map<String, Set<String>> scopes = const {},
    String icon = PositionStyle.defaultIcon,
    int color = PositionStyle.defaultColor,
  }) => run(
    () => _repo.create(
      churchId,
      name: name,
      permissions: permissions,
      scopes: scopes,
      icon: icon,
      color: color,
    ),
  );

  Future<bool> update(
    Position p,
    String name,
    Set<String> permissions, {
    Map<String, Set<String>> scopes = const {},
    String? icon,
    int? color,
  }) => run(
    () => _repo.update(
      churchId,
      p,
      name: name,
      permissions: permissions,
      scopes: scopes,
      icon: icon,
      color: color,
    ),
  );

  Future<bool> saveBuiltIn(
    BuiltInPosition b,
    Set<String> permissions, {
    Map<String, Set<String>> scopes = const {},
    String? name,
    String? icon,
    int? color,
  }) => run(
    () => _repo.saveBuiltIn(
      churchId,
      b,
      permissions,
      scopes: scopes,
      name: name,
      icon: icon,
      color: color,
    ),
  );

  /// 기본 직급(교역자 · 회원)을 지운다 (기본값으로 돌아간다).
  Future<bool> deleteBuiltIn(BuiltInPosition b) =>
      run(() => _repo.deleteBuiltIn(churchId, b));

  Future<bool> delete(Position p) => run(() => _repo.delete(churchId, p));

  /// 교인의 역할을 바꾼다 (교회 관리자 인원을 고칠 때).
  Future<bool> setRole(Member m, Role role) =>
      run(() => _memberRepo.setRole(churchId, m.id, role), blocking: false);

  /// 교인에게 직급을 주거나 뺀다 ([position]이 null이면 뺀다).
  Future<bool> assign(Member m, Position? position) =>
      run(() => _repo.assign(churchId, m.id, position), blocking: false);
}
