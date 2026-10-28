import '../../../core/icons.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../church/data/church_repository.dart';
import '../view_model/invite_codes_view_model.dart';

/// 초대 코드. 코드를 만들 때 역할 · 부서 · 일회용 여부를 정해 두면, 그 코드로 들어온 사람은
/// 그 역할과 부서로 신청된다. 알맞은 사람에게 보낼 초대 메시지를 복사해 전달한다.
/// 코드는 일정 기간만 유효하고, 필요하면 새로 발급하거나 폐기한다.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<InviteCodesViewModel>(
      create: (context) => InviteCodesViewModel(
        AppScope.read(context).churches,
        AppScope.read(context).departments,
        me,
      ),
      builder: (context, vm) {
        final narrow = MediaQuery.sizeOf(context).width < kNarrow;
        final createButton = FilledButton.icon(
          onPressed: vm.busy ? null : () => _create(context, vm),
          icon: const Icon(AppIcons.plus, size: 18),
          label: Text(
            '새 코드 만들기 (${ChurchRepository.inviteValidity.inDays}일 유효)',
          ),
        );
        return Card(
          child: Padding(
            padding: EdgeInsets.all(narrow ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.key),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '초대 코드',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!narrow) createButton,
                  ],
                ),
                // 좁은 화면에서는 제목 아래 줄에서 가로로 가득 채운다.
                if (narrow) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: createButton),
                ],
                if (vm.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                StreamBuilder<List<Department>>(
                  stream: vm.departments,
                  builder: (context, deptSnap) {
                    final names = {
                      for (final d in deptSnap.data ?? const <Department>[])
                        d.id: d.name,
                    };
                    return StreamBuilder<List<InviteCode>>(
                      stream: vm.codes,
                      builder: (context, snap) {
                        final active = (snap.data ?? const <InviteCode>[])
                            .where((c) => !c.isExpired)
                            .toList();
                        if (active.isEmpty) {
                          return Text(
                            '유효한 초대 코드가 없어요. 새 코드를 만들어 주세요.',
                            style: TextStyle(color: context.palette.muted),
                          );
                        }
                        return Column(
                          children: [
                            for (final c in active)
                              _CodeRow(
                                code: c,
                                vm: vm,
                                churchName: me.churchName,
                                departmentNames: [
                                  for (final id in c.departmentIds)
                                    if (names[id] != null) names[id]!,
                                ],
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context, InviteCodesViewModel vm) async {
    final form = await showAppDialog<_InviteForm>(
      context,
      child: _NewInviteForm(vm: vm),
    );
    if (form == null) return;
    await vm.create(
      role: form.role,
      departmentIds: form.departmentIds,
      singleUse: form.singleUse,
    );
  }
}

class _InviteForm {
  const _InviteForm(this.singleUse, this.role, this.departmentIds);

  final bool singleUse;
  final Role role;
  final List<String> departmentIds;
}

/// 새 초대 코드: 역할 · 부서 · 필수 정보 · 일회용 여부를 고른다.
class _NewInviteForm extends StatefulWidget {
  const _NewInviteForm({required this.vm});

  final InviteCodesViewModel vm;

  @override
  State<_NewInviteForm> createState() => _NewInviteFormState();
}

class _NewInviteFormState extends State<_NewInviteForm> {
  bool _singleUse = false;
  Role _role = Role.member;
  String? _department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('초대 코드 만들기', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('역할', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<Role>(
          showSelectedIcon: false,
          segments: [
            const ButtonSegment(value: Role.member, label: Text('교인')),
            ButtonSegment(
              value: Role.staff,
              label: const Text('교역자'),
              enabled: widget.vm.canInviteStaff,
            ),
          ],
          selected: {_role},
          onSelectionChanged: (s) => setState(() => _role = s.first),
        ),
        if (!widget.vm.canInviteStaff)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '교역자 코드는 교회 관리자만 만들 수 있어요.',
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        StreamBuilder<List<Department>>(
          stream: widget.vm.departments,
          builder: (context, snap) {
            final list = snap.data ?? const <Department>[];
            return DropdownButtonFormField<String?>(
              initialValue: _department,
              isExpanded: true,
              borderRadius: BorderRadius.circular(AppRadius.control),
              decoration: const InputDecoration(labelText: '소속 부서'),
              items: [
                const DropdownMenuItem(value: null, child: Text('없음')),
                for (final d in list)
                  DropdownMenuItem(value: d.id, child: Text(d.name)),
              ],
              onChanged: (v) => setState(() => _department = v),
            );
          },
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _singleUse,
          onChanged: (v) => setState(() => _singleUse = v ?? false),
          title: const Text('일회용'),
        ),
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
                _InviteForm(_singleUse, _role, [?_department]),
              ),
              child: const Text('코드 만들기'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({
    required this.code,
    required this.vm,
    required this.churchName,
    required this.departmentNames,
  });

  final InviteCode code;
  final InviteCodesViewModel vm;
  final String churchName;
  final List<String> departmentNames;

  String get _roleLabel => code.role == Role.staff ? '교역자' : '교인';

  String get _target => [
    _roleLabel,
    if (code.singleUse) '일회용',
    if (departmentNames.isNotEmpty) departmentNames.join(', '),
  ].join(' · ');

  /// "3일 남음" / "5시간 남음" 처럼 남은 유효기간을 보여준다.
  String _remaining() {
    final left = code.expiresAt.difference(DateTime.now());
    if (left.inDays >= 1) {
      return '${left.inDays}일 남음 · ${fmtDate(code.expiresAt)}까지';
    }
    if (left.inHours >= 1) return '${left.inHours}시간 남음';
    return '곧 만료';
  }

  /// 그대로 보낼 수 있는 초대 메시지.
  String _message() {
    return [
      '$churchName에 초대합니다.',
      '역할: $_roleLabel${departmentNames.isEmpty ? '' : ' · 부서: ${departmentNames.join(', ')}'}',
      '초대 코드: ${code.code} (${fmtDate(code.expiresAt)}까지)',
      '앱에서 "초대 코드로 입장"을 눌러 이 코드를 입력해 주세요.',
      if (kIsWeb) Uri.base.origin,
    ].join('\n');
  }

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// 초대 코드만 복사한다.
  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code.code));
    _snack(context, '초대 코드를 복사했어요.');
  }

  /// 초대 메시지를 공유한다. 공유 창을 쓸 수 없는 환경이면 메시지를 복사해 준다.
  Future<void> _share(BuildContext context) async {
    final message = _message();
    try {
      await SharePlus.instance.share(
        ShareParams(text: message, title: '$churchName 초대'),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        _snack(context, '공유할 수 없어 초대 메시지를 복사했어요. 받는 분께 붙여넣어 보내 주세요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            code.code,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(_target, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            _remaining(),
            style: TextStyle(color: palette.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          // 좁은 화면에서도 한 줄에 들어가도록 버튼을 폭에 맞춰 나눈다.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(context),
                  icon: const Icon(AppIcons.copy, size: 18),
                  label: const Text('코드 복사'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(AppIcons.shareNetwork, size: 18),
                  label: const Text('공유'),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: vm.busy ? null : () => vm.revoke(code.code),
                child: const Text('폐기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
