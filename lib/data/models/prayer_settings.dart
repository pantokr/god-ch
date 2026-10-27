import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'prayer.dart';
import 'reaction.dart';

/// 누가 기도제목을 쓸 수 있는가.
enum PrayerWriters {
  member('member', '교인 전체'),
  staff('staff', '교역자만');

  const PrayerWriters(this.id, this.label);

  final String id;
  final String label;

  static PrayerWriters fromId(String? id) =>
      values.firstWhere((w) => w.id == id, orElse: () => member);
}

/// 기도 요청을 교회가 어떻게 운영할지. 기도 요청 페이지를 고칠 때 교역자가 정한다.
/// `churches/{id}/settings/prayer`에 저장되고, 권한과 관련된 항목은 `firestore.rules`가 같은 기준으로 막는다.
/// 설정한 적이 없으면 [standard]의 값이다.
class PrayerSettings {
  const PrayerSettings({
    this.writers = PrayerWriters.member,
    this.allowPrivate = true,
    this.defaultVisibility = PrayerVisibility.public,
    this.reactions = const {'pray', 'love', 'cheer', 'peace'},
    this.showCounts = true,
    this.memberDelete = true,
    this.requireDeleteReason = true,
    this.staffComments = true,
    this.privateResponses = true,
    this.logPrivateAccess = true,
  });

  static const standard = PrayerSettings();

  /// 쓸 수 있는 사람. (규칙이 막는다)
  final PrayerWriters writers;

  /// 교역자 전용 비공개 글을 허용하는가. (규칙이 막는다)
  final bool allowPrivate;

  /// 글을 쓸 때 처음 골라져 있는 공개 범위.
  final PrayerVisibility defaultVisibility;

  /// 쓸 수 있는 이모티콘 응원의 종류. 비면 응원 기능이 꺼진다. (규칙이 막는다)
  final Set<String> reactions;

  /// 이모티콘별 개수를 보여주는가.
  final bool showCounts;

  /// 교인이 본인 글을 지울 수 있는가. (규칙이 막는다)
  final bool memberDelete;

  /// 교역자가 타인의 글을 지울 때 사유를 필수로 받는가. (규칙이 막는다)
  final bool requireDeleteReason;

  /// 공개 글에 교역자 댓글을 허용하는가. (규칙이 막는다)
  final bool staffComments;

  /// 비공개 글에 교역자 응답을 허용하는가. (규칙이 막는다)
  final bool privateResponses;

  /// 교역자가 타인의 비공개 글을 열면 접근 기록을 남기는가.
  final bool logPrivateAccess;

  /// 응원 기능을 쓰는가.
  bool get reactionsOn => reactions.isNotEmpty;

  /// 지금 쓸 수 있는 이모티콘들 (정해진 순서대로).
  List<ReactionType> get reactionList => [
    for (final r in reactionTypes)
      if (reactions.contains(r.id)) r,
  ];

  PrayerSettings copyWith({
    PrayerWriters? writers,
    bool? allowPrivate,
    PrayerVisibility? defaultVisibility,
    Set<String>? reactions,
    bool? showCounts,
    bool? memberDelete,
    bool? requireDeleteReason,
    bool? staffComments,
    bool? privateResponses,
    bool? logPrivateAccess,
  }) => PrayerSettings(
    writers: writers ?? this.writers,
    allowPrivate: allowPrivate ?? this.allowPrivate,
    defaultVisibility: defaultVisibility ?? this.defaultVisibility,
    reactions: reactions ?? this.reactions,
    showCounts: showCounts ?? this.showCounts,
    memberDelete: memberDelete ?? this.memberDelete,
    requireDeleteReason: requireDeleteReason ?? this.requireDeleteReason,
    staffComments: staffComments ?? this.staffComments,
    privateResponses: privateResponses ?? this.privateResponses,
    logPrivateAccess: logPrivateAccess ?? this.logPrivateAccess,
  );

  factory PrayerSettings.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data();
    if (d == null) return standard;
    bool flag(String key, bool dflt) => d[key] is bool ? d[key] as bool : dflt;
    return PrayerSettings(
      writers: PrayerWriters.fromId(d['writers'] as String?),
      allowPrivate: flag('allowPrivate', true),
      defaultVisibility: d['defaultVisibility'] == 'private'
          ? PrayerVisibility.private
          : PrayerVisibility.public,
      reactions: d['reactions'] is List
          ? Set<String>.from(d['reactions'] as List)
          : standard.reactions,
      showCounts: flag('showCounts', true),
      memberDelete: flag('memberDelete', true),
      requireDeleteReason: flag('requireDeleteReason', true),
      staffComments: flag('staffComments', true),
      privateResponses: flag('privateResponses', true),
      logPrivateAccess: flag('logPrivateAccess', true),
    );
  }

  Map<String, Object> toMap() => {
    'writers': writers.id,
    'allowPrivate': allowPrivate,
    // 비공개를 허용하지 않으면 기본값도 공개다.
    'defaultVisibility': allowPrivate
        ? defaultVisibility.name
        : PrayerVisibility.public.name,
    'reactions': [
      for (final r in reactionTypes)
        if (reactions.contains(r.id)) r.id,
    ],
    'showCounts': showCounts,
    'memberDelete': memberDelete,
    'requireDeleteReason': requireDeleteReason,
    'staffComments': staffComments,
    'privateResponses': privateResponses,
    'logPrivateAccess': logPrivateAccess,
  };

  @override
  bool operator ==(Object other) =>
      other is PrayerSettings && _sameMap(toMap(), other.toMap());

  @override
  int get hashCode => Object.hashAll(
    toMap().values.map((v) => v is List ? Object.hashAll(v) : v),
  );

  static bool _sameMap(Map<String, Object> a, Map<String, Object> b) {
    for (final k in a.keys) {
      final x = a[k], y = b[k];
      if (x is List && y is List) {
        if (x.length != y.length || !x.every(y.contains)) return false;
      } else if (x != y) {
        return false;
      }
    }
    return true;
  }
}
