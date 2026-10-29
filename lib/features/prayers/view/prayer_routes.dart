import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/prayer.dart';
import '../../church/view/member_gate.dart';
import '../view_model/prayer_lookup_view_model.dart';
import 'prayer_detail_page.dart';
import 'prayer_editor_page.dart';

/// 주소 `/churches/:cid/prayers/:pid`: 기도제목 상세.
/// 승인된 교인에게만 보이고, 글은 주소의 ID로 불러온다.
class PrayerDetailRoute extends StatelessWidget {
  const PrayerDetailRoute({
    super.key,
    required this.churchId,
    required this.prayerId,
    this.initial,
  });

  final String churchId;
  final String prayerId;

  /// 목록에서 넘어올 때 이미 가진 글. 주소로 바로 열면 null.
  final Prayer? initial;

  @override
  Widget build(BuildContext context) {
    return MemberGate(
      churchId: churchId,
      builder: (context, me) =>
          PrayerDetailPage(me: me, prayerId: prayerId, initial: initial),
    );
  }
}

/// 주소 `/churches/:cid/prayers/new`: 새 기도제목 쓰기. `?aff=`가 있으면 그 소속이 기본 게시 범위다.
class PrayerCreateRoute extends StatelessWidget {
  const PrayerCreateRoute({
    super.key,
    required this.churchId,
    this.affiliationId,
  });

  final String churchId;
  final String? affiliationId;

  @override
  Widget build(BuildContext context) {
    return MemberGate(
      churchId: churchId,
      builder: (context, me) =>
          PrayerEditorPage(me: me, defaultAffiliationId: affiliationId),
    );
  }
}

/// 주소 `/churches/:cid/prayers/:pid/edit`: 기도제목 수정. 글은 주소의 ID로 불러온다.
class PrayerEditRoute extends StatelessWidget {
  const PrayerEditRoute({
    super.key,
    required this.churchId,
    required this.prayerId,
  });

  final String churchId;
  final String prayerId;

  @override
  Widget build(BuildContext context) {
    final back = Routes.prayer(churchId, prayerId);
    return MemberGate(
      churchId: churchId,
      builder: (context, me) => ViewModelBuilder<PrayerLookupViewModel>(
        create: (context) => PrayerLookupViewModel(
          AppScope.read(context).prayers,
          churchId,
          prayerId,
        ),
        builder: (context, vm) => StreamBuilder<Prayer?>(
          stream: vm.prayer,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final prayer = snap.data;
            // 없는 글이거나 내 글이 아니면(규칙상 수정할 수 없다) 고칠 수 없다.
            if (prayer == null || prayer.authorId != me.id || prayer.deleted) {
              return SubPage(
                title: '기도제목 수정',
                fallbackLocation: back,
                child: const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: Text('수정할 수 없는 기도제목입니다.')),
                  ),
                ),
              );
            }
            return PrayerEditorPage(me: me, prayer: prayer);
          },
        ),
      ),
    );
  }
}
