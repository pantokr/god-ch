import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../church/view/church_info_fields.dart';
import '../view_model/church_registry_view_model.dart';

/// 앱 운영자가 교회를 직접 등록한다. 전화번호는 비워 둘 수 있다.
class RegisterChurchDialog extends StatefulWidget {
  const RegisterChurchDialog({super.key, required this.vm});

  final ChurchRegistryViewModel vm;

  @override
  State<RegisterChurchDialog> createState() => _RegisterChurchDialogState();
}

class _RegisterChurchDialogState extends State<RegisterChurchDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.vm.register(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
    );
    if (ok) {
      navigator.pop();
    } else if (mounted) {
      setState(() {
        _busy = false;
        _error = widget.vm.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('교회 등록', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            '등록하면 바로 교회가 만들어지고, 등록한 운영자가 그 교회의 교회 운영자가 돼요. '
            '이후 초대 코드를 만들어 실제 교회 운영자를 초대하고 역할을 넘길 수 있어요.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          ChurchInfoFields(
            name: _name,
            phone: _phone,
            address: _address,
            phoneRequired: false,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
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
                onPressed: _busy ? null : _submit,
                child: const Text('등록'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
