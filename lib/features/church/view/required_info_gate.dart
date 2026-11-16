import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../../../data/models/profile_field.dart';
import '../../auth/view/profile_extra_fields.dart';
import '../view_model/required_info_view_model.dart';

/// 교회가 필수로 요청한 정보(주소 · 생년월일)가 내 교인 정보에 비어 있으면, 제출하기 전에는 교회를 쓸 수 없다.
/// 입장한 뒤에 교회가 필수 항목을 새로 정했을 때, 이미 들어와 있는 교인이 한 번 제출하게 한다.
/// 제출한 정보는 이 교회에만 저장되고, 한 번 낸 뒤에는 교인이 고칠 수 없다 (`firestore.rules`가 강제한다).
class RequiredInfoGate extends StatelessWidget {
  const RequiredInfoGate({
    super.key,
    required this.me,
    required this.requirements,
    required this.child,
  });

  final Member me;
  final Stream<Set<ProfileField>> requirements;
  final Widget child;

  /// 이 교회가 요청했는데 내 교인 정보에 비어 있는 항목.
  static Set<ProfileField> missing(Member me, Set<ProfileField> required) => {
    if (required.contains(ProfileField.address) && me.address.trim().isEmpty)
      ProfileField.address,
    if (required.contains(ProfileField.birthDate) &&
        me.birthDate.trim().isEmpty)
      ProfileField.birthDate,
  };

  @override
  Widget build(BuildContext context) {
    // 앱 개발자는 교인이 아니라 채울 정보가 없다.
    if (me.isOperatorView) return child;
    return StreamBuilder<Set<ProfileField>>(
      stream: requirements,
      builder: (context, snap) {
        final missingNow = missing(me, snap.data ?? const {});
        if (missingNow.isEmpty) return child;
        return _RequiredInfoPage(me: me, fields: missingNow);
      },
    );
  }
}

class _RequiredInfoPage extends StatefulWidget {
  const _RequiredInfoPage({required this.me, required this.fields});

  final Member me;
  final Set<ProfileField> fields;

  @override
  State<_RequiredInfoPage> createState() => _RequiredInfoPageState();
}

class _RequiredInfoPageState extends State<_RequiredInfoPage> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _birthDate = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  Future<void> _save(RequiredInfoViewModel vm) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final f = widget.fields;
    // 저장하면 교인 정보가 바뀌어 이 화면은 저절로 사라진다.
    await vm.save(
      address: f.contains(ProfileField.address) ? _address.text : '',
      birthDate: f.contains(ProfileField.birthDate) ? _birthDate.text : '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fields;
    return ViewModelBuilder<RequiredInfoViewModel>(
      create: (context) => RequiredInfoViewModel(
        AppScope.read(context).members,
        widget.me.churchId,
      ),
      builder: (context, vm) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: PageFrame(
              maxWidth: 520,
              inset: true,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${widget.me.churchName} 필수 정보',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        ProfileExtraFields(
                          address: _address,
                          birthDate: _birthDate,
                          showAddress: f.contains(ProfileField.address),
                          showBirthDate: f.contains(ProfileField.birthDate),
                          requireAddress: f.contains(ProfileField.address),
                          requireBirthDate: f.contains(ProfileField.birthDate),
                        ),
                        if (vm.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.go(Routes.churchList),
                              child: const Text('내 교회 목록'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: vm.busy ? null : () => _save(vm),
                              child: const Text('저장'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
