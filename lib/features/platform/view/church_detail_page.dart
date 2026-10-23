import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme.dart';
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
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.palette.surface,
              border: Border(bottom: BorderSide(color: context.palette.border)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad - 8),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '교회 목록',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(Routes.adminChurches),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            church.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
                  child: ChurchDetailView(church: church),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
