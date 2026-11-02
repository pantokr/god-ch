import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'reaction.dart';

/// 기도 요청을 교회가 어떻게 운영할지. 기도 요청 페이지를 고칠 때 교역자가 정한다.
/// 글을 쓸 수 있는 사람은 설정이 아니라 직급 권한(`prayer.write`)으로 정한다.
/// `churches/{id}/settings/prayer`에 저장되고, 권한과 관련된 항목은 `firestore.rules`가 같은 기준으로 막는다.
/// 설정한 적이 없으면 [standard]의 값이다.
class PrayerSettings {
  const PrayerSettings({
    this.allowPrivate = true,
    this.reactions = const {'pray', 'love', 'cheer', 'peace'},
    this.showCounts = true,
    this.requireDeleteReason = true,
    this.privateResponses = true,
    this.logPrivateAccess = true,
    this.allowComments = true,
    this.showViews = true,
    this.showAuthor = true,
  });

  static const standard = PrayerSettings();

  /// 교역자 전용 비공개 글을 허용하는가. (규칙이 막는다)
  final bool allowPrivate;

  /// 쓸 수 있는 이모티콘 응원의 종류. 비면 응원 기능이 꺼진다. (규칙이 막는다)
  final Set<String> reactions;

  /// 이모티콘별 개수를 보여주는가.
  final bool showCounts;

  /// 교역자가 타인의 글을 지울 때 사유를 필수로 받는가. (규칙이 막는다)
  final bool requireDeleteReason;

  /// 비공개 글에 교역자 응답을 허용하는가. (규칙이 막는다)
  final bool privateResponses;

  /// 교역자가 타인의 비공개 글을 열면 접근 기록을 남기는가.
  final bool logPrivateAccess;

  /// 공개 글에 댓글을 달 수 있는가. (규칙이 막는다)
  final bool allowComments;

  /// 조회수를 보여 주는가. 끄면 숫자만 감추고 기록은 계속 쌓는다.
  final bool showViews;

  /// 글쓴이(이름)를 보여 주는가.
  final bool showAuthor;

  /// 응원 기능을 쓰는가.
  bool get reactionsOn => reactions.isNotEmpty;

  /// 지금 쓸 수 있는 이모티콘들 (정해진 순서대로).
  List<ReactionType> get reactionList => [
    for (final r in reactionTypes)
      if (reactions.contains(r.id)) r,
  ];

  PrayerSettings copyWith({
    bool? allowPrivate,
    Set<String>? reactions,
    bool? showCounts,
    bool? requireDeleteReason,
    bool? privateResponses,
    bool? logPrivateAccess,
    bool? allowComments,
    bool? showViews,
    bool? showAuthor,
  }) => PrayerSettings(
    allowPrivate: allowPrivate ?? this.allowPrivate,
    reactions: reactions ?? this.reactions,
    showCounts: showCounts ?? this.showCounts,
    requireDeleteReason: requireDeleteReason ?? this.requireDeleteReason,
    privateResponses: privateResponses ?? this.privateResponses,
    logPrivateAccess: logPrivateAccess ?? this.logPrivateAccess,
    allowComments: allowComments ?? this.allowComments,
    showViews: showViews ?? this.showViews,
    showAuthor: showAuthor ?? this.showAuthor,
  );

  factory PrayerSettings.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data();
    if (d == null) return standard;
    bool flag(String key, bool dflt) => d[key] is bool ? d[key] as bool : dflt;
    return PrayerSettings(
      allowPrivate: flag('allowPrivate', true),
      reactions: d['reactions'] is List
          ? Set<String>.from(d['reactions'] as List)
          : standard.reactions,
      showCounts: flag('showCounts', true),
      requireDeleteReason: flag('requireDeleteReason', true),
      privateResponses: flag('privateResponses', true),
      logPrivateAccess: flag('logPrivateAccess', true),
      allowComments: flag('allowComments', true),
      showViews: flag('showViews', true),
      showAuthor: flag('showAuthor', true),
    );
  }

  Map<String, Object> toMap() => {
    'allowPrivate': allowPrivate,
    'reactions': [
      for (final r in reactionTypes)
        if (reactions.contains(r.id)) r.id,
    ],
    'showCounts': showCounts,
    'requireDeleteReason': requireDeleteReason,
    'privateResponses': privateResponses,
    'logPrivateAccess': logPrivateAccess,
    'allowComments': allowComments,
    'showViews': showViews,
    'showAuthor': showAuthor,
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
