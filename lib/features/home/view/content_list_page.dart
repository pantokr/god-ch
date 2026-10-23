import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../view_model/content_list_view_model.dart';
import 'content_tiles.dart';
import 'content_widgets.dart';

/// 메인의 "더보기": 한 종류의 콘텐츠 전체 목록.
class ContentListPage extends StatelessWidget {
  const ContentListPage({super.key, required this.me, required this.kind});

  final Member me;
  final ContentKind kind;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ContentListViewModel>(
      create: (context) => ContentListViewModel(
        AppScope.read(context).contents,
        me.churchId,
        kind,
      ),
      builder: (context, vm) {
        void open(ChurchContent c) =>
            context.push(Routes.contentDetail(me.churchId, kind, c.id));
        return SingleChildScrollView(
          child: PageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageTitle(
                  title: kind.label,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (me.isAdmin)
                        OutlinedButton.icon(
                          onPressed: () => context.go(
                            Routes.contentEdit(me.churchId, kind: kind),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('편집'),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: '메인',
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(Routes.home(me.churchId)),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ],
                  ),
                ),
                ContentStream(
                  stream: vm.items,
                  loadingHeight: 200,
                  builder: (context, items) {
                    if (items.isEmpty) {
                      return EmptyHint('아직 등록된 ${kind.label}이(가) 없어요.');
                    }
                    return switch (kind) {
                      ContentKind.photo => ColumnWrap(
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
                      ContentKind.sermon => ColumnWrap(
                        children: [
                          for (final c in items)
                            SermonCard(content: c, onTap: () => open(c)),
                        ],
                      ),
                      ContentKind.event => ColumnWrap(
                        wide: 2,
                        children: [
                          for (final c in items)
                            EventTile(content: c, onTap: () => open(c)),
                        ],
                      ),
                      ContentKind.devotion => ColumnWrap(
                        wide: 1,
                        children: [
                          for (final c in items)
                            DevotionCard(content: c, onTap: () => open(c)),
                        ],
                      ),
                      ContentKind.notice => ColumnWrap(
                        wide: 1,
                        children: [
                          for (final c in items)
                            NoticeRow(content: c, onTap: () => open(c)),
                        ],
                      ),
                    };
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
