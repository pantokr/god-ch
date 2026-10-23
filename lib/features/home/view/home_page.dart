import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../view_model/home_view_model.dart';
import 'content_tiles.dart';
import 'content_widgets.dart';
import 'notice_carousel.dart';

/// 교회 메인: 위에는 공지사항 캐러셀, 아래로 일정 · 사진첩 · 설교영상 · 말씀묵상.
/// 구역마다 "더보기"로 전체 목록에 들어가고, 항목을 누르면 상세 화면이 열린다.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>(
      create: (context) =>
          HomeViewModel(AppScope.read(context).contents, me.churchId),
      builder: (context, vm) {
        void open(ChurchContent c) =>
            context.push(Routes.contentDetail(me.churchId, c.kind, c.id));
        void more(ContentKind k) =>
            context.push(Routes.contentList(me.churchId, k));
        final hint = me.isStaff ? '\n왼쪽 "메인 페이지 편집"에서 추가할 수 있어요.' : '';

        return SingleChildScrollView(
          child: PageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ContentStream(
                  stream: vm.notices,
                  loadingHeight: 200,
                  builder: (context, items) => items.isEmpty
                      ? EmptyHint('등록된 공지사항이 없어요.$hint')
                      : NoticeCarousel(notices: items, onOpen: open),
                ),

                SectionHeader(
                  title: '일정',
                  onMore: () => more(ContentKind.event),
                ),
                ContentStream(
                  stream: vm.events,
                  builder: (context, items) => items.isEmpty
                      ? EmptyHint('다가오는 일정이 없어요.$hint')
                      : ColumnWrap(
                          wide: 2,
                          children: [
                            for (final c in items)
                              EventTile(content: c, onTap: () => open(c)),
                          ],
                        ),
                ),

                SectionHeader(
                  title: '사진첩',
                  onMore: () => more(ContentKind.photo),
                ),
                ContentStream(
                  stream: vm.photos,
                  builder: (context, items) => items.isEmpty
                      ? EmptyHint('올려진 사진이 없어요.$hint')
                      : ColumnWrap(
                          narrow: 2,
                          children: [
                            for (final c in items)
                              AspectRatio(
                                aspectRatio: 4 / 3,
                                child: PhotoTile(
                                  content: c,
                                  onTap: () => open(c),
                                ),
                              ),
                          ],
                        ),
                ),

                SectionHeader(
                  title: '설교영상',
                  onMore: () => more(ContentKind.sermon),
                ),
                ContentStream(
                  stream: vm.sermons,
                  builder: (context, items) => items.isEmpty
                      ? EmptyHint('올려진 설교영상이 없어요.$hint')
                      : ColumnWrap(
                          children: [
                            for (final c in items)
                              SermonCard(content: c, onTap: () => open(c)),
                          ],
                        ),
                ),

                SectionHeader(
                  title: '말씀묵상',
                  onMore: () => more(ContentKind.devotion),
                ),
                ContentStream(
                  stream: vm.devotions,
                  builder: (context, items) => items.isEmpty
                      ? EmptyHint('오늘의 말씀묵상이 아직 없어요.$hint')
                      : DevotionCard(
                          content: items.first,
                          onTap: () => open(items.first),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
