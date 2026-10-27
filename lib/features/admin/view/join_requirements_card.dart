import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../../../data/models/profile_field.dart';
import '../view_model/join_requirements_view_model.dart';

/// 입장 시 필수 정보: 주소 · 생년월일을 고르면, 초대 코드로 입장을 신청하는 회원은 입력해야 한다.
/// 코드를 만들 때가 아니라 여기서 교회 전체에 한 번 정한다. 전화번호 인증은 아직 쓸 수 없다.
class JoinRequirementsCard extends StatelessWidget {
  const JoinRequirementsCard({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<JoinRequirementsViewModel>(
      create: (context) => JoinRequirementsViewModel(
        AppScope.read(context).churches,
        me.churchId,
      ),
      builder: (context, vm) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined),
                  const SizedBox(width: 10),
                  Text(
                    '입장 시 필수 정보',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<Set<ProfileField>>(
                stream: vm.requirements,
                builder: (context, snap) {
                  final current = snap.data ?? const <ProfileField>{};
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in ProfileField.values)
                        FilterChip(
                          label: Text(f.label),
                          selected: current.contains(f),
                          onSelected: vm.busy || !snap.hasData
                              ? null
                              : (on) async {
                                  final ok = await confirmChange(
                                    context,
                                    title:
                                        '${f.label} 필수 정보를 ${on ? '켤까요' : '끌까요'}?',
                                    body: on
                                        ? '앞으로 입장을 요청하는 사람은 ${f.label}을 입력해야 해요.'
                                        : '${f.label}을 입력하지 않아도 입장을 요청할 수 있어요.',
                                  );
                                  if (ok) await vm.toggle(current, f, on);
                                },
                        ),
                      const FilterChip(
                        label: Text('전화번호 인증'),
                        selected: false,
                        onSelected: null,
                      ),
                    ],
                  );
                },
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
