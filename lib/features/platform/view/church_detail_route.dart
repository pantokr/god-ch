import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church.dart';
import '../view_model/church_lookup_view_model.dart';
import 'church_detail_page.dart';

/// 주소 `/admin/churches/:cid`: 교회 상세 관리. 교회는 주소의 ID로 불러오므로
/// 링크로 열거나 새로고침해도 된다.
class ChurchDetailRoute extends StatelessWidget {
  const ChurchDetailRoute({super.key, required this.churchId});

  final String churchId;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchLookupViewModel>(
      create: (context) => ChurchLookupViewModel(
        AppScope.read(context).churchRegistry,
        churchId,
      ),
      builder: (context, vm) => StreamBuilder<Church?>(
        stream: vm.church,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final church = snap.data;
          if (church == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('찾을 수 없는 교회입니다.'),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.go(Routes.adminChurches),
                      child: const Text('교회 목록으로'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ChurchDetailPage(church: church);
        },
      ),
    );
  }
}
