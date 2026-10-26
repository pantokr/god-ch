import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/layout/responsive.dart';
import '../../../data/models/church.dart';
import 'church_detail_view.dart';

/// 교회 상세 관리 화면. 교회 목록에서 "관리"를 누르면 열리고, 돌아가기로 목록에 돌아간다.
class ChurchDetailPage extends StatelessWidget {
  const ChurchDetailPage({super.key, required this.church});

  final Church church;

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 바 없이 뒤로가기 버튼만 내용 위에 둔다.
                  IconButton(
                    tooltip: '교회 목록',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.adminChurches),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(child: ChurchDetailView(church: church)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
