import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import 'content_widgets.dart';

/// 콘텐츠 관리: 교회 운영자 전용. 공지·일정 같은 글의 종류를 고르면 그 종류의 글을 관리한다.
/// 페이지의 구성(메뉴 대분류, 구조)은 "페이지 편집"에서 따로 고친다.
class ContentManagePage extends StatelessWidget {
  const ContentManagePage({super.key, required this.me});

  final Member me;

  static const _icons = {
    ContentKind.notice: Icons.campaign_outlined,
    ContentKind.event: Icons.event_outlined,
    ContentKind.photo: Icons.photo_library_outlined,
    ContentKind.sermon: Icons.smart_display_outlined,
    ContentKind.devotion: Icons.menu_book_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle(
              title: '콘텐츠 관리',
              subtitle: '페이지에 보여줄 공지·일정 같은 글을 종류별로 올리고 고쳐요.',
            ),
            ColumnWrap(
              wide: 3,
              narrow: 2,
              children: [
                for (final k in ContentKind.values)
                  InkWell(
                    onTap: () =>
                        context.go(Routes.contentEdit(me.churchId, kind: k)),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: context.palette.surface,
                        border: Border.all(color: context.palette.border),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        children: [
                          Icon(_icons[k], color: context.palette.brand),
                          const SizedBox(height: 8),
                          Text(
                            k.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
