import '../../../core/widgets/app_loader.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../view_model/church_visibility_view_model.dart';

/// 노출: 공개로 두면 교회 탐색에 나타나 누구나 입장을 요청하고(승인해야 교인), 비공개로 두면
/// 탐색에 나오지 않고 초대 코드로만 들어온다. 바꿀 때는 한 번 더 확인받는다.
class ChurchVisibilityCard extends StatelessWidget {
  const ChurchVisibilityCard({super.key, required this.me});

  final Member me;

  Future<void> _change(
    BuildContext context,
    ChurchVisibilityViewModel vm,
    bool listed,
  ) async {
    final ok = await confirmChange(
      context,
      title: listed ? '공개 탐색에 노출할까요?' : '비공개로 바꿀까요?',
      body: listed
          ? '누구나 교회를 찾아 입장을 요청할 수 있어요. 요청은 승인해야 교인이 됩니다.'
          : '교회 탐색에서 사라지고 초대 코드로만 들어올 수 있어요. 이미 보낸 요청은 그대로 남아요.',
      confirmLabel: listed ? '공개' : '비공개',
    );
    if (ok) await vm.setListed(listed);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchVisibilityViewModel>(
      create: (context) => ChurchVisibilityViewModel(
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
                  const Icon(AppIcons.globeHemisphereEast),
                  const SizedBox(width: 10),
                  Text('노출', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<bool>(
                stream: vm.listed,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: AppLoader()),
                    );
                  }
                  return RadioGroup<bool>(
                    groupValue: snap.data!,
                    onChanged: (v) {
                      if (v != null && v != snap.data && !vm.busy) {
                        _change(context, vm, v);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<bool>(
                          value: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('공개'),
                          subtitle: Text('교회 탐색에 노출 · 요청 후 승인'),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          contentPadding: EdgeInsets.zero,
                          title: Text('비공개'),
                          subtitle: Text('초대 코드로만 입장'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (vm.error != null)
                Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
