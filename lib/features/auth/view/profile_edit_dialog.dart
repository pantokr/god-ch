import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/thumbnail_field.dart';
import '../../../core/widgets/required_label.dart';
import '../view_model/profile_edit_view_model.dart';
import 'profile_extra_fields.dart';

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
  final _address = TextEditingController();
  final _birthDate = TextEditingController();
  final _photo = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _birthDate.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _save(ProfileEditViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (await vm.save(
      _name.text,
      _phone.text,
      address: _address.text,
      birthDate: _birthDate.text,
      photoUrl: _photo.text,
    )) {
      if (!widget.embedded) navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('내 정보를 저장했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<ProfileEditViewModel>(
      create: (context) =>
          ProfileEditViewModel(AppScope.read(context).profiles),
      builder: (context, vm) {
        if (vm.loaded && !_filled) {
          _filled = true;
          _phone.text = vm.profile?.phone ?? '';
          _address.text = vm.profile?.address ?? '';
          _birthDate.text = vm.profile?.birthDate ?? '';
          _photo.text = vm.profile?.photoUrl ?? '';
        }
        final hasProfile = vm.profile != null;
        // 페이지에 놓일 때(embedded)는 칸 사이를 넉넉하게 띄운다.
        final gap = SizedBox(height: widget.embedded ? 22 : AppField.gap);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('내 정보', style: theme.textTheme.titleLarge),
            SizedBox(height: widget.embedded ? 24 : 16),
            if (hasProfile) ...[
              ThumbnailField(
                controller: _photo,
                name: widget.name,
                label: '썸네일(프로필 사진)',
                upload: vm.uploadPhoto,
              ),
              gap,
            ],
            TextField(
              controller: _name,
              maxLength: 30,
              decoration: InputDecoration(label: const RequiredLabel('이름')),
            ),
            if (hasProfile) ...[
              gap,
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: InputDecoration(label: const RequiredLabel('전화번호')),
                onSubmitted: (_) => _save(vm),
              ),
              gap,
              ProfileExtraFields(address: _address, birthDate: _birthDate),
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
