import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/activity_log.dart';
import '../../auth/data/auth_repository.dart';

/// 회원별 접속 · 활동 기록 (`activityLogs`). 쓰기는 앱 곳곳에서, 읽기는 앱 운영자만 한다.
/// 기록은 부가 기능이라 실패해도 원래 동작을 막지 않고, 오프라인이면 기다리지 않고 포기한다.
class ActivityLogRepository {
  ActivityLogRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final AuthRepository _auth;

  static const _collection = 'activityLogs';

  /// 요약 · 이름 · ID의 최대 길이 (`firestore.rules`와 일치).
  static const maxSummary = 100;
  static const maxName = 60;
  static const maxId = 64;

  /// 기록이 이 시간 안에 서버에 닿지 않으면 기다리지 않는다 (로그아웃 같은 곳이 멈추지 않게).
  static const _wait = Duration(seconds: 3);

  String _cut(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);

  /// 활동 하나를 기록한다. 로그인한 계정이 없거나 쓰기가 실패하면 조용히 넘어간다.
  Future<void> record(
    ActivityType type, {
    String churchId = '',
    String targetId = '',
    String summary = '',
  }) async {
    try {
      final data = <String, Object?>{
        'uid': _auth.uid,
        'userName': _cut(_auth.displayName, maxName),
        'type': type.id,
        'createdAt': FieldValue.serverTimestamp(),
        if (churchId.isNotEmpty) 'churchId': _cut(churchId, maxId),
        if (targetId.isNotEmpty) 'targetId': _cut(targetId, maxId),
        if (summary.isNotEmpty) 'summary': _cut(summary, maxSummary),
      };
      await _db.collection(_collection).doc(newId()).set(data).timeout(_wait);
    } catch (e) {
      if (kDebugMode) debugPrint('활동 기록 실패(${type.id}): $e');
    }
  }

  /// 기록을 기다리지 않고 남긴다 (화면 동작이 느려지지 않게).
  void log(
    ActivityType type, {
    String churchId = '',
    String targetId = '',
    String summary = '',
  }) => unawaited(
    record(type, churchId: churchId, targetId: targetId, summary: summary),
  );

  // 복합 색인이 필요 없게 설계했다 (test/no_composite_query_test.dart): 조회는 같음(==) 조건만 쓰고
  // orderBy를 붙이지 않는다. 결과는 문서 ID 순서로 나오고, ID를 시간 역순으로 만들기 때문에([newId]) 그 순서가 곧 최신순이다.

  /// 기록 ID: 시간이 지날수록 이름순으로 앞에 오도록 (9999999999999 - 지금 밀리초)를 앞에 붙인다.
  static String newId() {
    final reversed = (9999999999999 - DateTime.now().millisecondsSinceEpoch)
        .toString()
        .padLeft(13, '0');
    final rnd = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final tail = List.generate(6, (_) => chars[rnd.nextInt(chars.length)]);
    return '${reversed}_${tail.join()}';
  }

  /// 최근 기록 (앱 운영자 전용, 최신 순). 더 보려면 [limit]을 늘린다.
  Stream<List<ActivityLog>> recent({int limit = 200}) =>
      _db.collection(_collection).limit(limit).snapshots().map(_parse);

  /// 한 회원의 기록 (앱 운영자 전용, 최신 순).
  Stream<List<ActivityLog>> byUser(String uid, {int limit = 200}) => _db
      .collection(_collection)
      .where('uid', isEqualTo: uid)
      .limit(limit)
      .snapshots()
      .map(_parse);

  List<ActivityLog> _parse(QuerySnapshot<Map<String, dynamic>> s) => [
    for (final d in s.docs) ?ActivityLog.fromDoc(d),
  ];
}

/// 쓰기가 끝난 뒤에 활동을 한 줄 남긴다 (쓰기가 실패하면 남기지 않는다). [log]가 null이면 아무것도 하지 않는다.
extension ActivityLogged<T> on Future<T> {
  Future<T> logged(
    ActivityLogRepository? log,
    ActivityType type, {
    String churchId = '',
    String targetId = '',
    String summary = '',
  }) => then((value) {
    log?.log(type, churchId: churchId, targetId: targetId, summary: summary);
    return value;
  });
}
