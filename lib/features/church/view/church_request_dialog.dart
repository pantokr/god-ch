import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../view_model/church_request_view_model.dart';
import 'church_info_fields.dart';

/// 교회 생성 요청 폼: 교회 이름, 전화번호(형식 자동), 주소(도로명 주소 검색).
/// 요청을 보내면 앱 운영자가 확인한 뒤 교회가 만들어진다.
class ChurchRequestDialog extends StatefulWidget {
  const ChurchRequestDialog({super.key});

  @override
  State<ChurchRequestDialog> createState() => _ChurchRequestDialogState();
}

class _ChurchRequestDialogState extends State<ChurchRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit(ChurchRequestViewModel vm) {
    if (!_form.currentState!.validate()) return;
    vm.submit(name: _name.text, phone: _phone.text, address: _address.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<ChurchRequestViewModel>(
      create: (context) =>
          ChurchRequestViewModel(AppScope.read(context).churchRequests),
      builder: (context, vm) {
        if (vm.submitted) return _Submitted(name: _name.text.trim());
        return Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('교회 생성 요청', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '요청을 보내면 앱 운영자가 확인한 뒤 교회를 만들어 드려요. 승인되면 요청한 분이 교회 운영자가 됩니다.',
                style: TextStyle(color: context.palette.muted),
              ),
              const SizedBox(height: 20),
              ChurchInfoFields(name: _name, phone: _phone, address: _address),
              if (vm.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  vm.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: vm.busy ? null : () => _submit(vm),
                    child: const Text('요청 보내기'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Submitted extends StatelessWidget {
  const _Submitted({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 48,
          color: context.palette.brand,
        ),
        const SizedBox(height: 16),
        Text(
          '요청을 보냈어요',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '"$name" 생성 요청을 앱 운영자가 확인하면 교회가 만들어져요.\n진행 상황은 첫 화면의 신청 현황에서 볼 수 있어요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.muted),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ),
      ],
    );
  }
}
