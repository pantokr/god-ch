import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 모임 일정을 교회가 어떻게 운영할지. 모임 일정 설정에서 교회 운영자가 정한다.
/// `churches/{id}/settings/meeting`에 저장되고, 좋아요 · 댓글은 `firestore.rules`가 같은 기준으로 막는다.
/// 설정한 적이 없으면 [standard]의 값(모두 허용 · 공개)이다.
class MeetingSettings {
  const MeetingSettings({
    this.allowLikes = true,
    this.allowComments = true,
    this.commentsPublic = true,
    this.showLikeCount = true,
    this.showViews = true,
  });

  static const standard = MeetingSettings();

  /// 좋아요를 누를 수 있는가. (규칙이 막는다)
  final bool allowLikes;

  /// 교인이 댓글을 쓸 수 있는가. (규칙이 막는다)
  final bool allowComments;

  /// 댓글을 다른 교인에게도 보여 주는가. 끄면 본인과 일정 삭제 권한이 있는 사람만 본다. (규칙이 막는다)
  final bool commentsPublic;

  /// 좋아요 수를 보여 주는가. 끄면 하트만 보이고 기록은 계속 쌓는다.
  final bool showLikeCount;

  /// 조회수를 보여 주는가. 끄면 숫자만 감추고 기록은 계속 쌓는다.
  final bool showViews;

  MeetingSettings copyWith({
    bool? allowLikes,
    bool? allowComments,
    bool? commentsPublic,
    bool? showLikeCount,
    bool? showViews,
  }) => MeetingSettings(
    allowLikes: allowLikes ?? this.allowLikes,
    allowComments: allowComments ?? this.allowComments,
    commentsPublic: commentsPublic ?? this.commentsPublic,
    showLikeCount: showLikeCount ?? this.showLikeCount,
    showViews: showViews ?? this.showViews,
  );

  factory MeetingSettings.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data();
    if (d == null) return standard;
    bool flag(String key) => d[key] is bool ? d[key] as bool : true;
    return MeetingSettings(
      allowLikes: flag('allowLikes'),
      allowComments: flag('allowComments'),
      commentsPublic: flag('commentsPublic'),
      showLikeCount: flag('showLikeCount'),
      showViews: flag('showViews'),
    );
  }

  Map<String, Object> toMap() => {
    'allowLikes': allowLikes,
    'allowComments': allowComments,
    'commentsPublic': commentsPublic,
    'showLikeCount': showLikeCount,
    'showViews': showViews,
  };

  @override
  bool operator ==(Object other) =>
      other is MeetingSettings &&
      allowLikes == other.allowLikes &&
      allowComments == other.allowComments &&
      commentsPublic == other.commentsPublic &&
      showLikeCount == other.showLikeCount &&
      showViews == other.showViews;

  @override
  int get hashCode => Object.hash(
    allowLikes,
    allowComments,
    commentsPublic,
    showLikeCount,
    showViews,
  );
}
