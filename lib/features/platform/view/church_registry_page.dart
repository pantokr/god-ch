import '../../../core/icons.dart';
import 'church_closures_admin_card.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church.dart';
import '../../church/view/church_requests_admin_card.dart';
import '../view_model/church_registry_view_model.dart';
import 'register_church_page.dart';
import 'registered_churches.dart';

/// 앱 운영자 > 교회 관리: 교회 생성 요청 처리와 등록된 교회 목록을 한 화면에 나열한다.
/// 교회 상세 관리(정보·교인·초대 코드)는 목록에서 교회의 "관리"를 눌러 연다.
class ChurchRegistryPage extends StatelessWidget {
  const ChurchRegistryPage({super.key});

  /// 교회를 고르면 교회 관리자와 같은 교회 화면이 열린다. 뒤로 가면 목록에 돌아온다.
  void _openChurch(BuildContext context, Church church) =>
      context.push(Routes.home(church.id));

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
              // 제목은 위쪽 바에 있다. 생성 버튼만 오른쪽에 둔다.
              PageTitle(
                title: '',
                gap: 16,
                action: FilledButton.icon(
                  onPressed: () => showRegisterChurchPage(context, vm: vm),
                  icon: const Icon(AppIcons.plus, size: 18),
                  label: const Text('교회 생성'),
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const ChurchRequestsAdminCard(),
              const SizedBox(height: 24),
              const ChurchClosuresAdminCard(),
              const SizedBox(height: 24),
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
