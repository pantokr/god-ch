import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../prayers/view/my_prayers_page.dart';
import '../view_model/my_reflections_view_model.dart';
import 'content_widgets.dart';

/// 하단 탭 "내 활동": 기도 · 말씀 페이지 구성에 따라 자동으로 정해지는 내 글 모음.
/// 기도 요청 페이지가 있으면 "내 기도제목", 말씀 묵상 페이지가 있으면 "내 묵상"이 생긴다.
class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key, required this.me, required this.pages});

  final Member me;
  final List<PageConfig> pages;

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  MyActivity? _selected;

  @override
  Widget build(BuildContext context) {
    final activities = MyActivity.from(widget.pages);
    if (activities.isEmpty) {
      return const PageFrame(child: EmptyHint('내 활동 없음'));
    }
    final current = activities.contains(_selected)
        ? _selected!
        : activities.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activities.length > 1)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final a in activities)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(a.label),
                      selected: a == current,
                      onSelected: (_) => setState(() => _selected = a),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: switch (current) {
            MyActivity.prayer => MyPrayersPage(
              key: const ValueKey('mine/prayer'),
              me: widget.me,
              onWrite: () => context.push(Routes.newPrayer(widget.me.churchId)),
            ),
            MyActivity.devotion => _MyReflections(
              key: const ValueKey('mine/devotion'),
              me: widget.me,
            ),
          },
        ),
      ],
    );
  }
}

/// 내가 말씀 묵상에 남긴 글 목록.
class _MyReflections extends StatelessWidget {
  const _MyReflections({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ViewModelBuilder<MyReflectionsViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MyReflectionsViewModel(
          scope.contents,
          scope.reflections,
          me.churchId,
        );
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: StreamBuilder<List<MyReflection>>(
            stream: vm.items,
            builder: (context, snap) {
              if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snap.data!;
              if (items.isEmpty) return const EmptyHint('쓴 묵상 없음');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final m in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.devotion.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(m.reflection.text),
                              if (m.reflection.updatedAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  fmtDate(m.reflection.updatedAt!),
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
