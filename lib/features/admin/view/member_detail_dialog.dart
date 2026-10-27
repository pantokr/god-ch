import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/mvvm/view_model.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../core/widgets/thumbnail_field.dart';
import '../../auth/view/profile_extra_fields.dart';
import '../../../core/widgets/app_inputs.dart';

/// 한 교회 안에서의 소속 정보를 고치는 칸. 고칠 수 있는 항목은 권한에 따라 다르다.
class MembershipEditor {
  const MembershipEditor({
    required this.member,
    required this.departments,
    this.canRole = false,
    this.canStatus = false,
  });

  final Member member;

  /// 이 교회에 있는 부서 전체.
  final List<Department> departments;
  final bool canRole;
  final bool canStatus;
}

/// 한 교회에서 바뀐 항목. 바뀌지 않은 항목은 null이다.
class MembershipChange {
  const MembershipChange(
    this.member, {
    this.departmentIds,
    this.role,
    this.status,
  });

  final Member member;
  final List<String>? departmentIds;
  final Role? role;
  final MemberStatus? status;

  bool get isEmpty => departmentIds == null && role == null && status == null;
}

class MemberDetailResult {
  const MemberDetailResult({
    required this.name,
    required this.phone,
    required this.address,
    required this.birthDate,
    this.photoUrl = '',
    required this.changes,
  });

  final String name;
  final String phone;
  final String address;
  final String birthDate;
  final String photoUrl;
  final List<MembershipChange> changes;
}

/// 회원 상세 관리: 이름·전화번호와 교회별 소속 부서·역할·상태.
/// 교회 운영자(교회 안)와 앱 운영자(전체 회원)가 같은 창을 쓴다.
class MemberDetailDialog extends StatefulWidget {
  const MemberDetailDialog({
    super.key,
    required this.vm,
    required this.title,
    this.subtitle = '',
    required this.name,
    required this.phone,
    this.address = '',
    this.birthDate = '',
    this.photoUrl = '',
    this.onUploadPhoto,
    required this.memberships,
    required this.onSave,
    this.canEditProfile = true,
    this.showChurchNames = false,
    this.onRemove,
    this.onBlock,
  });

  /// 저장 중·오류 표시에 쓴다.
  final ViewModel vm;
  final String title;

  /// 제목 아래 보조 문구 (로그인 아이디).
  final String subtitle;
  final String name;
  final String phone;
  final String address;
  final String birthDate;
  final String photoUrl;

  /// 썸네일을 올리는 함수. null이면 썸네일은 보여주기만 하고 바꾸지 못한다 (앱 운영자만 바꾼다).
  final Future<String?> Function(String fileName, Uint8List bytes)?
  onUploadPhoto;
  final List<MembershipEditor> memberships;
  final Future<bool> Function(MemberDetailResult result) onSave;

  /// 이름·전화번호를 고칠 수 있는가 (교역자는 소속 부서만 고칠 수 있다).
  final bool canEditProfile;

  /// 여러 교회에 속할 수 있는 화면(앱 운영자)에서 교회 이름을 제목으로 보여준다.
  final bool showChurchNames;

  /// 회원을 추방한다 (확인까지 거친 뒤 지웠으면 true). null이면 추방 버튼을 보이지 않는다.
  final Future<bool> Function()? onRemove;

  /// 회원을 차단 목록에 올린다 (추방과 같은 방식). null이면 차단 버튼을 보이지 않는다.
  final Future<bool> Function()? onBlock;

  static const roleLabel = {
    Role.member: '교인',
    Role.staff: '교역자',
    Role.admin: '교회 관리자',
  };
  static const statusLabel = {
    MemberStatus.pending: '승인 대기',
    MemberStatus.approved: '승인됨',
    MemberStatus.disabled: '비활성',
    MemberStatus.removed: '추방됨',
  };

  @override
  State<MemberDetailDialog> createState() => _MemberDetailDialogState();
}

class _MemberDetailDialogState extends State<MemberDetailDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);
  late final _address = TextEditingController(text: widget.address);
  late final _birthDate = TextEditingController(text: widget.birthDate);
  late final _photo = TextEditingController(text: widget.photoUrl);
  late final List<Set<String>> _depts = [
    for (final m in widget.memberships) {...m.member.departmentIds},
  ];
  late final List<Role> _roles = [
    for (final m in widget.memberships) m.member.role,
  ];
  late final List<MemberStatus> _statuses = [
    for (final m in widget.memberships) m.member.status,
  ];

  @override
  void initState() {
    super.initState();
    widget.vm.clearError();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _birthDate.dispose();
    _photo.dispose();
    super.dispose();
  }

  bool _sameIds(Iterable<String> a, Iterable<String> b) {
    final x = a.toSet();
    final y = b.toSet();
    return x.length == y.length && x.containsAll(y);
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final changes = <MembershipChange>[];
    for (var i = 0; i < widget.memberships.length; i++) {
      final e = widget.memberships[i];
      final m = e.member;
      final change = MembershipChange(
        m,
        departmentIds: _sameIds(_depts[i], m.departmentIds)
            ? null
            : [
                for (final d in e.departments)
                  if (_depts[i].contains(d.id)) d.id,
                // 삭제되었거나 보이지 않는 부서는 그대로 둔다.
                for (final id in m.departmentIds)
                  if (!e.departments.any((d) => d.id == id)) id,
              ],
        role: e.canRole && _roles[i] != m.role ? _roles[i] : null,
        status: e.canStatus && _statuses[i] != m.status ? _statuses[i] : null,
      );
      if (!change.isEmpty) changes.add(change);
    }
    final ok = await widget.onSave(
      MemberDetailResult(
        name: _name.text,
        phone: _phone.text,
        address: _address.text,
        birthDate: _birthDate.text,
        photoUrl: _photo.text,
        changes: changes,
      ),
    );
    if (!ok) return;
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('저장했어요.')));
  }

  Future<void> _remove() async {
    final navigator = Navigator.of(context);
    if (await widget.onRemove!()) navigator.pop();
  }

  Future<void> _block() async {
    final navigator = Navigator.of(context);
    if (await widget.onBlock!()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = TextStyle(color: context.palette.muted);
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          if (widget.subtitle.isNotEmpty)
            Text(
              widget.subtitle,
              style: TextStyle(color: context.palette.muted),
            ),
          const SizedBox(height: 16),
          ThumbnailField(
            controller: _photo,
            name: widget.name,
            label: '썸네일(프로필 사진)',
            enabled: widget.onUploadPhoto != null,
            upload: widget.onUploadPhoto ?? (_, _) async => null,
          ),
          AppField.spacer,
          TextField(
            controller: _name,
            enabled: widget.canEditProfile,
            maxLength: 30,
            decoration: const InputDecoration(labelText: '이름'),
          ),
          AppField.spacer,
          TextField(
            controller: _phone,
            enabled: widget.canEditProfile,
            keyboardType: TextInputType.phone,
            maxLength: 20,
            decoration: const InputDecoration(labelText: '전화번호'),
          ),
          AppField.spacer,
          ProfileExtraFields(
            address: _address,
            birthDate: _birthDate,
            enabled: widget.canEditProfile,
          ),
          if (widget.memberships.isEmpty) ...[
            const SizedBox(height: 8),
            Text('소속된 교회가 없어요.', style: muted),
          ],
          for (var i = 0; i < widget.memberships.length; i++) ...[
            const Divider(height: 32),
            if (widget.showChurchNames)
              Text(
                widget.memberships[i].member.churchName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            if (widget.memberships[i].canRole ||
                widget.memberships[i].canStatus)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (widget.memberships[i].canRole)
                      Expanded(
                        child: AppDropdown<Role>(
                          value: _roles[i],
                          label: '역할',
                          items: [
                            for (final r in Role.values)
                              DropdownMenuItem(
                                value: r,
                                child: Text(MemberDetailDialog.roleLabel[r]!),
                              ),
                          ],
                          onChanged: (v) => setState(() => _roles[i] = v!),
                        ),
                      ),
                    if (widget.memberships[i].canRole &&
                        widget.memberships[i].canStatus)
                      const SizedBox(width: 12),
                    if (widget.memberships[i].canStatus)
                      Expanded(
                        child: AppDropdown<MemberStatus>(
                          value: _statuses[i],
                          label: '상태',
                          items: [
                            // 추방은 따로 있는 추방 버튼으로 한다. 이미 추방된 사람일 때만 현재 상태로 보인다.
                            for (final s in MemberStatus.values)
                              if (s != MemberStatus.removed ||
                                  _statuses[i] == MemberStatus.removed)
                                DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    MemberDetailDialog.statusLabel[s] ?? s.name,
                                  ),
                                ),
                          ],
                          onChanged: (v) => setState(() => _statuses[i] = v!),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text('소속 부서', style: muted),
            if (widget.memberships[i].departments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('만들어진 부서가 없어요.', style: muted),
              ),
            for (final d in widget.memberships[i].departments)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(d.name),
                // 교회 운영자는 모든 부서에 자동으로 속한다.
                value: _roles[i] == Role.admin || _depts[i].contains(d.id),
                onChanged: _roles[i] == Role.admin
                    ? null
                    : (v) => setState(() {
                        if (v ?? false) {
                          _depts[i].add(d.id);
                        } else {
                          _depts[i].remove(d.id);
                        }
                      }),
              ),
          ],
          if (widget.vm.error != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.vm.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onBlock != null)
                TextButton.icon(
                  onPressed: widget.vm.busy ? null : _block,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('차단'),
                ),
              if (widget.onRemove != null) ...[
                TextButton.icon(
                  onPressed: widget.vm.busy ? null : _remove,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.person_remove_outlined, size: 18),
                  label: const Text('추방'),
                ),
                const Spacer(),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.vm.busy ? null : _save,
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
