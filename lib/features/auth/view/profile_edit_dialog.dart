import 'package:flutter/material.dart';

import '../../../core/widgets/toast.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/discard_guard.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/thumbnail_field.dart';
import '../../../core/widgets/labeled_field.dart';
import '../view_model/profile_edit_view_model.dart';

/// 내 정보를 보고 이름·전화번호를 고치는 대화상자 내용.
class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({
    super.key,
    required this.name,
    this.details = const [],
    this.embedded = false,
  });

  final String name;
  final List<ProfileDetail> details;

  /// 설정 탭 안에 놓일 때 true: 저장해도 닫지 않고, 취소 버튼이 없다.
  final bool embedded;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late final _name = TextEditingController(text: widget.name);
  final _phone = TextEditingController();
  final _photo = TextEditingController();
  bool _filling = false;
  bool _filled = false;

  /// 불러온(또는 마지막으로 저장한) 이름 · 전화번호 · 사진. 이와 다르면 저장하지 않은 내용이 있는 것이다.
  List<String> _base = const [];

  List<String> _now() => [
    _name.text.trim(),
    _phone.text.trim(),
    _photo.text.trim(),
  ];

  /// 내 정보 페이지(embedded)에서만 뒤로 갈 때 묻는다. 대화상자는 닫기로 바로 닫는다.
  bool _dirty() {
    if (!widget.embedded || !_filled) return false;
    final now = _now();
    for (var i = 0; i < now.length; i++) {
      if (now[i] != _base[i]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _save(ProfileEditViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (await vm.save(_name.text, _phone.text, photoUrl: _photo.text)) {
      _base = _now();
      if (!widget.embedded) navigator.pop();
      showToastOn(messenger, '내 정보를 저장했어요.');
    }
  }

  @override
  Widget build(BuildContext context) => DiscardGuard(
    isDirty: _dirty,
    listenable: Listenable.merge([_name, _phone, _photo]),
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<ProfileEditViewModel>(
      create: (context) =>
          ProfileEditViewModel(AppScope.read(context).profiles),
      builder: (context, vm) {
        if (vm.loaded && !_filling) {
          _filling = true;
          // 입력칸 값은 그린 뒤에 채운다: 그리는 도중에 바꾸면 이 칸을 지켜보는 저장 확인(DiscardGuard)이 다시 그려져 오류가 난다.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _phone.text = vm.profile?.phone ?? '';
            _photo.text = vm.profile?.photoUrl ?? '';
            _base = _now();
            setState(() => _filled = true);
          });
        }
        final hasProfile = vm.profile != null;
        // 페이지에 놓일 때(embedded)는 칸 사이를 넉넉하게 띄운다.
        final gap = SizedBox(height: widget.embedded ? 22 : AppField.gap);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 페이지에 놓일 때(embedded)는 상단 탭에 제목이 있다.
            if (!widget.embedded) ...[
              Text('내 정보', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
            ],
            if (hasProfile) ...[
              ThumbnailField(
                controller: _photo,
                name: widget.name,
                label: '썸네일(프로필 사진)',
                upload: vm.uploadPhoto,
              ),
              gap,
            ],
            if ((vm.profile?.loginId ?? '').isNotEmpty) ...[
              LabeledField(
                label: '아이디',
                child: TextFormField(
                  key: ValueKey(vm.profile!.loginId),
                  initialValue: vm.profile!.loginId,
                  readOnly: true,
                  enabled: false,
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
              gap,
            ],
            LabeledField(
              label: '이름',
              required: true,
              child: TextField(
                controller: _name,
                maxLength: 30,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
            if (hasProfile) ...[
              gap,
              LabeledField(
                label: '전화번호',
                required: true,
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: const InputDecoration(counterText: ''),
                  onSubmitted: (_) => _save(vm),
                ),
              ),
            ],
            for (final d in widget.details)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${d.label}  ${d.value}',
                  style: TextStyle(color: context.palette.muted),
                ),
              ),
            if (vm.error != null) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            SizedBox(height: widget.embedded ? 28 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.embedded) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton(
                  onPressed: vm.busy || !vm.loaded ? null : () => _save(vm),
                  child: const Text('저장'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
