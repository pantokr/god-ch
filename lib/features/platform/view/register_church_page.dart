import 'package:flutter/material.dart';

import '../../../core/layout/sub_page.dart';
import '../../church/view/church_info_fields.dart';
import '../view_model/church_registry_view_model.dart';

/// 교회 생성 페이지로 이동한다 (앱 운영자 > 교회 관리). 만들면 이전 화면(교회 목록)으로 돌아온다.
Future<void> showRegisterChurchPage(
  BuildContext context, {
  required ChurchRegistryViewModel vm,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  MaterialPageRoute(
    builder: (context) => SubPage(
      title: '',
      barTitle: '교회 생성',
      fallbackLocation: '',
      onBack: () => Navigator.of(context).maybePop(),
      child: RegisterChurchPage(vm: vm),
    ),
  ),
);

/// 앱 운영자가 교회를 직접 생성한다. 전화번호는 비워 둘 수 있다.
class RegisterChurchPage extends StatefulWidget {
  const RegisterChurchPage({super.key, required this.vm});

  final ChurchRegistryViewModel vm;

  @override
  State<RegisterChurchPage> createState() => _RegisterChurchPageState();
}

class _RegisterChurchPageState extends State<RegisterChurchPage> {
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChurchInfoFields(name: _name, phone: _phone, address: _address),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: const Text('생성'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
