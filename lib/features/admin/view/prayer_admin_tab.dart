import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../../prayers/view/prayer_list.dart';
import '../view_model/prayer_admin_view_model.dart';

/// 공개·비공개·삭제된 기도제목 전체를 보고 관리한다.
class PrayerAdminTab extends StatelessWidget {
  const PrayerAdminTab({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PrayerAdminViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return PrayerAdminViewModel(scope.prayers, scope.members, me.churchId);
      },
      builder: (context, vm) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<PrayerFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: PrayerFilter.all, label: Text('전체')),
                ButtonSegment(
                  value: PrayerFilter.private,
                  label: Text('교역자 전용'),
                ),
                ButtonSegment(value: PrayerFilter.deleted, label: Text('삭제됨')),
              ],
              selected: {vm.filter},
              onSelectionChanged: (s) => vm.setFilter(s.first),
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, String>>(
              stream: vm.authorNames,
              builder: (context, names) => PrayerGrid(
                prayers: vm.allPrayers,
                where: vm.matches,
                me: me,
                emptyText: '해당하는 기도제목이 없어요.',
                authorNames: names.data ?? const {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
