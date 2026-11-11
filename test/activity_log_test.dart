import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/activity_log.dart';
import 'package:god_ch/data/models/church.dart';
import 'package:god_ch/features/activity/data/activity_log_repository.dart';
import 'package:god_ch/features/platform/data/church_registry_repository.dart';
import 'package:god_ch/features/platform/view_model/activity_log_view_model.dart';

class _Logs extends Fake implements ActivityLogRepository {
  _Logs(this.items);

  final List<ActivityLog> items;
  final requested = <String>[];

  @override
  Stream<List<ActivityLog>> recent({int limit = 200}) {
    requested.add('recent/$limit');
    return Stream.value(items);
  }

  @override
  Stream<List<ActivityLog>> byUser(String uid, {int limit = 200}) {
    requested.add('byUser/$uid/$limit');
    return Stream.value([
      for (final l in items)
        if (l.uid == uid) l,
    ]);
  }
}

class _Registry extends Fake implements ChurchRegistryRepository {
  @override
  Stream<List<Church>> churches() => Stream.value([
    const Church(id: 'c1', name: '은혜교회', phone: '', address: ''),
  ]);
}

ActivityLog _log(
  String id,
  String uid,
  String name,
  ActivityType type, {
  String churchId = 'c1',
  String summary = '',
}) => ActivityLog(
  id: id,
  uid: uid,
  userName: name,
  type: type,
  churchId: churchId,
  summary: summary,
  at: DateTime(2026, 11, 11, 9, 30),
);

void main() {
  group('종류 목록', () {
    test('저장 값(id)이 서로 다르다', () {
      final ids = [for (final t in ActivityType.values) t.id];
      expect(ids.toSet().length, ids.length);
    });

    test('모든 종류가 firestore.rules의 허용 목록에 있다', () {
      final rules = File('firestore.rules').readAsStringSync();
      final start = rules.indexOf('match /activityLogs/');
      expect(start, greaterThan(0), reason: '규칙에 activityLogs가 있어야 한다');
      final block = rules.substring(start, rules.indexOf('match /admins/'));
      final allowed = RegExp(r"type in \[([^\]]*)\]")
          .firstMatch(block)!
          .group(1)!;
      final listed = RegExp(r"'([^']+)'")
          .allMatches(allowed)
          .map((m) => m.group(1)!)
          .toSet();
      expect(listed, {for (final t in ActivityType.values) t.id});
    });

    test('저장된 값으로 종류를 찾는다', () {
      expect(ActivityType.fromId('login'), ActivityType.login);
      expect(ActivityType.fromId('nope'), isNull);
    });
  });

  group('활동 기록 ViewModel', () {
    final items = [
      _log('1', 'u1', '김성도', ActivityType.login),
      _log('2', 'u1', '김성도', ActivityType.prayerCreate),
      _log('3', 'u2', '이집사', ActivityType.meetingCreate, summary: '성경 공부'),
    ];

    test('갈래와 검색어로 거른다', () {
      final vm = ActivityLogViewModel(_Logs(items), _Registry());
      const names = {'c1': '은혜교회'};
      expect(vm.apply(items, names), hasLength(3));
      vm.setGroup(ActivityGroup.prayer);
      expect(vm.apply(items, names).map((l) => l.id), ['2']);
      vm.setGroup(null);
      vm.setQuery('성경');
      expect(vm.apply(items, names).map((l) => l.id), ['3']);
      vm.setQuery('은혜');
      expect(vm.apply(items, names), hasLength(3));
      vm.setQuery('이집사');
      expect(vm.apply(items, names).map((l) => l.id), ['3']);
    });

    test('회원을 고르면 그 회원 기록을 새로 가져오고, 더 보기는 한도를 늘린다', () {
      final repo = _Logs(items);
      final vm = ActivityLogViewModel(repo, _Registry());
      expect(repo.requested, ['recent/100']);
      vm.focusUser('u1', '김성도');
      expect(repo.requested.last, 'byUser/u1/100');
      vm.loadMore();
      expect(repo.requested.last, 'byUser/u1/200');
      vm.clearFocus();
      expect(repo.requested.last, 'recent/100');
    });
  });
}
