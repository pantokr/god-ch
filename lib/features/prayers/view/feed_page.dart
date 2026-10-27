import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../view_model/prayer_list_view_model.dart';
import 'prayer_list.dart';

/// 공개 기도제목 피드. 작성자 이름은 표시하지 않는다.
/// [department]가 있으면 그 부서 전용 글만, 없으면 교회 전체 글을 보여준다.
class FeedPage extends StatelessWidget {
  const FeedPage({
    super.key,
    required this.me,
    required this.onWrite,
    this.department,
  });

  final Member me;
  final Department? department;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PrayerListViewModel>(
      create: (context) => PrayerListViewModel(
        AppScope.read(context).prayers
            .publicFeed(me.churchId, departmentId: department?.id),
      ),
      builder: (context, vm) => PrayerList(
        prayers: vm.prayers,
        me: me,
        title: department == null ? '교회 기도제목' : '${department!.name} 기도제목',
        emptyText: '아직 나눠진 기도제목이 없어요.\n첫 기도제목을 나눠 보세요.',
        showReactions: true,
        onWrite: onWrite,
      ),
    );
  }
}
