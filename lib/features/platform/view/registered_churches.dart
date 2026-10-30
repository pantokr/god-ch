import '../../../core/widgets/app_loader.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../core/layout/manage_list_row.dart';
import '../../../core/theme.dart';
import '../../../data/models/church.dart';
import '../view_model/church_registry_view_model.dart';
import '../../../core/widgets/app_inputs.dart';

/// 등록된 교회 목록. 각 교회의 "관리"를 누르면 교회 상세 관리 화면이 열린다.
class RegisteredChurches extends StatelessWidget {
  const RegisteredChurches({
    super.key,
    required this.vm,
    required this.onManage,
  });

  final ChurchRegistryViewModel vm;
  final void Function(Church church) onManage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => _list(context),
    );
  }

  Widget _list(BuildContext context) {
    return StreamBuilder<List<Church>>(
      stream: vm.churches,
      builder: (context, snap) {
        final all = snap.data ?? const <Church>[];
        final churches = all.where(vm.matches).toList();
        final hasSample = all.any(
          (c) => c.name == ChurchRegistryViewModel.sampleName,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchField(hint: '교회 이름, 주소, 전화번호 검색', onChanged: vm.setQuery),
            const SizedBox(height: 16),
            Text(
              '등록된 교회 (${all.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (snap.hasError)
              Text('불러오지 못했습니다\n${snap.error}')
            else if (!snap.hasData)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: AppLoader()),
              )
            else if (churches.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      all.isEmpty ? '아직 등록된 교회가 없어요.' : '해당하는 교회가 없어요.',
                      style: TextStyle(color: context.palette.muted),
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < churches.length; i++) ...[
                      if (i > 0) const Divider(),
                      _ChurchRow(
                        church: churches[i],
                        onManage: () => onManage(churches[i]),
                      ),
                    ],
                  ],
                ),
              ),
            if (snap.hasData && !hasSample) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: vm.busy ? null : vm.registerSample,
                  icon: const Icon(AppIcons.church, size: 18),
                  label: const Text('예시 교회 추가 (PL교회)'),
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _ChurchRow extends StatelessWidget {
  const _ChurchRow({required this.church, required this.onManage});

  final Church church;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    // 회원 관리·인원 관리와 같은 줄 모양: 이름 · 주소 · 전화번호 · [관리].
    return ManageListRow(
      leading: ManageListRow.avatar(
        context,
        church.name,
        imageUrl: church.thumbnailUrl,
      ),
      title: church.name,
      line1: church.address,
      line2: church.phone,
      onTap: onManage,
      trailing: [TextButton(onPressed: onManage, child: const Text('관리'))],
    );
  }
}
