import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../data/models/member.dart';

/// 교회 탈퇴: 확인을 거쳐 이 교회의 교인에서 빠진다. 교회 관리자는 탈퇴할 수 없다 (교회를 맡을 사람이 없어지므로).
Future<void> leaveChurch(BuildContext context, Member member) async {
  final messenger = ScaffoldMessenger.of(context);
  final members = AppScope.read(context).members;
  final ok = await confirmChange(
    context,
    title: '${member.churchName} 교회 탈퇴',
    body: '다시 들어오려면 새로 신청해야 해요.',
    confirmLabel: '교회 탈퇴',
  );
  if (!ok) return;
  try {
    await members.leave(member.churchId);
    messenger.showSnackBar(const SnackBar(content: Text('교회에서 탈퇴했어요')));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('교회 탈퇴에 실패했어요')));
  }
}
