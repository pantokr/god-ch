import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 말씀묵상을 교회가 어떻게 운영할지. 말씀묵상 설정에서 교회 운영자가 정한다.
/// `churches/{id}/settings/devotion`에 저장되고, 권한과 관련된 항목은 `firestore.rules`가 같은 기준으로 막는다.
/// 설정한 적이 없으면 [standard]의 값(작성자 비공개만 허용 안 함, 나머지는 모두 허용 · 공개)이다.
class DevotionSettings {
  const DevotionSettings({
    this.allowLikes = true,
    this.allowReflections = true,
    this.reflectionsPublic = true,
    this.showViews = true,
    this.showAuthor = true,
    this.showLikeCount = true,
    this.allowAnonymous = false,
  });

  static const standard = DevotionSettings();

  /// 좋아요를 누를 수 있는가. (규칙이 막는다)
  final bool allowLikes;

  /// 교인이 말씀에 댓글(내 묵상)을 남길 수 있는가. (규칙이 막는다)
  final bool allowReflections;

  /// 댓글을 다른 교인에게도 보여 주는가. 끄면 본인과 교역자만 본다. (규칙이 막는다)
  final bool reflectionsPublic;

  /// 조회수를 보여 주는가. 끄면 숫자만 감추고 기록은 계속 쌓는다.
  final bool showViews;

  /// 글쓴이(이름과 프로필 사진)를 보여 주는가.
  final bool showAuthor;

  /// 좋아요 수를 보여 주는가. 끄면 하트만 보이고 기록은 계속 쌓는다.
  final bool showLikeCount;

  /// 글쓴이가 자기 글의 작성자를 비공개(익명)로 할 수 있게 허용하는가. 비공개 글은 본인과 교역자 이상만 글쓴이를 본다. (규칙이 막는다)
  final bool allowAnonymous;

  DevotionSettings copyWith({
    bool? allowLikes,
    bool? allowReflections,
    bool? reflectionsPublic,
    bool? showViews,
    bool? showAuthor,
    bool? showLikeCount,
    bool? allowAnonymous,
  }) => DevotionSettings(
    allowLikes: allowLikes ?? this.allowLikes,
    allowReflections: allowReflections ?? this.allowReflections,
    reflectionsPublic: reflectionsPublic ?? this.reflectionsPublic,
    showViews: showViews ?? this.showViews,
    showAuthor: showAuthor ?? this.showAuthor,
    showLikeCount: showLikeCount ?? this.showLikeCount,
    allowAnonymous: allowAnonymous ?? this.allowAnonymous,
  );

  factory DevotionSettings.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data();
    if (d == null) return standard;
    bool flag(String key, [bool dflt = true]) =>
        d[key] is bool ? d[key] as bool : dflt;
    return DevotionSettings(
      allowLikes: flag('allowLikes'),
      allowReflections: flag('allowReflections'),
      reflectionsPublic: flag('reflectionsPublic'),
      showViews: flag('showViews'),
      showAuthor: flag('showAuthor'),
      showLikeCount: flag('showLikeCount'),
      allowAnonymous: flag('allowAnonymous', false),
    );
  }

  Map<String, Object> toMap() => {
    'allowLikes': allowLikes,
    'allowReflections': allowReflections,
    'reflectionsPublic': reflectionsPublic,
    'showViews': showViews,
    'showAuthor': showAuthor,
    'showLikeCount': showLikeCount,
    'allowAnonymous': allowAnonymous,
  };

  @override
  bool operator ==(Object other) =>
      other is DevotionSettings &&
      allowLikes == other.allowLikes &&
      allowReflections == other.allowReflections &&
      reflectionsPublic == other.reflectionsPublic &&
      showViews == other.showViews &&
      showAuthor == other.showAuthor &&
      showLikeCount == other.showLikeCount &&
      allowAnonymous == other.allowAnonymous;

  @override
  int get hashCode => Object.hash(
    allowLikes,
    allowReflections,
    reflectionsPublic,
    showViews,
    showAuthor,
    showLikeCount,
    allowAnonymous,
  );
}
