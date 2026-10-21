import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../view_model/create_church_view_model.dart';

/// 새 교회를 만든다. 만든 사람이 그 교회의 관리자가 된다.
class CreateChurchDialog extends StatefulWidget {
  const CreateChurchDialog({super.key});

  @override
  State<CreateChurchDialog> createState() => _CreateChurchDialogState();
}

class _CreateChurchDialogState extends State<CreateChurchDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<CreateChurchViewModel>(
      create: (context) =>
          CreateChurchViewModel(AppScope.read(context).churches),
      builder: (context, vm) {
        final code = vm.createdCode;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('교회 생성하기', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (code == null) ...[
              TextField(
                controller: _name,
                autofocus: true,
                maxLength: 50,
                decoration: const InputDecoration(labelText: '교회 이름'),
                onSubmitted: (_) => vm.submit(_name.text),
              ),
              const Text(
                '만든 사람이 이 교회의 관리자가 됩니다.',
                style: TextStyle(color: AppColors.muted),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  vm.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: vm.busy ? null : () => vm.submit(_name.text),
                    child: const Text('만들기'),
                  ),
                ],
              ),
            ] else ...[
              const Text('교회를 만들었어요. 교인들에게 이 초대 코드를 알려 주세요. (7일간 유효)'),
              const SizedBox(height: 16),
              Center(
                child: SelectableText(
                  code,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: code)),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('코드 복사'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
