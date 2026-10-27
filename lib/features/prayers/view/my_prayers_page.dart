import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../view_model/prayer_list_view_model.dart';
import 'prayer_list.dart';

/// 내가 쓴 기도제목. 비공개 글도 여기서는 보인다.
class MyPrayersPage extends StatelessWidget {
  const MyPrayersPage({super.key, required this.me, required this.onWrite});

  final Member me;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PrayerListViewModel>(
      create: (context) => PrayerListViewModel(
        AppScope.read(context).prayers.myPrayers(me.churchId),
      ),
      builder: (context, vm) => PrayerList(
        prayers: vm.prayers,
        me: me,
        title: '내 기도제목',
        emptyText: '작성한 기도제목이 없어요.',
        showReactions: false,
        onWrite: onWrite,
      ),
    );
  }
}
