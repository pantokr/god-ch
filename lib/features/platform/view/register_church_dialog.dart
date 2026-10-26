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
          Text(
            '등록하면 바로 교회가 만들어져요. 앱 운영자는 교회에 소속되지 않으므로, '
            '교회 관리에서 초대 코드를 만들어 교회 운영자가 될 분을 초대하고 "교회 운영자로 지정"해 주세요.',
            style: TextStyle(color: context.palette.muted),
          ),
          const SizedBox(height: 20),
          ChurchInfoFields(name: _name, phone: _phone, address: _address),
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
