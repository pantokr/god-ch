import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church.dart';
import '../../church/view/church_requests_admin_card.dart';
import '../view_model/church_registry_view_model.dart';
import 'register_church_dialog.dart';
import 'registered_churches.dart';

/// 앱 운영자 > 교회 관리: 교회 생성 요청 처리와 등록된 교회 목록을 한 화면에 나열한다.
/// 교회 상세 관리(정보·교인·초대 코드·부서)는 목록에서 교회의 "관리"를 눌러 연다.
class ChurchRegistryPage extends StatelessWidget {
  const ChurchRegistryPage({super.key});

  /// 교회 상세 관리를 주소로 연다. 브라우저 뒤로가기로 목록에 돌아온다.
  void _openChurch(BuildContext context, Church church) =>
      context.push(Routes.adminChurch(church.id));

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchRegistryViewModel>(
      create: (context) =>
          ChurchRegistryViewModel(AppScope.read(context).churchRegistry),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTitle(
                title: '교회 관리',
                subtitle: '교회 생성 요청을 처리하고, 등록된 교회를 관리해요.',
                action: FilledButton.icon(
                  onPressed: () => showAppDialog<void>(
                    context,
                    child: RegisterChurchDialog(vm: vm),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('교회 등록'),
                ),
              ),
              const ChurchRequestsAdminCard(),
              const SizedBox(height: 32),
              RegisteredChurches(
                vm: vm,
                onManage: (church) => _openChurch(context, church),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
