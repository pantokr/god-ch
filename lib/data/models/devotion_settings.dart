import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 말씀묵상을 교회가 어떻게 운영할지. 말씀묵상 설정에서 교회 운영자가 정한다.
/// `churches/{id}/settings/devotion`에 저장되고, 권한과 관련된 항목은 `firestore.rules`가 같은 기준으로 막는다.
/// 설정한 적이 없으면 [standard]의 값(모두 허용 · 공개)이다.
class DevotionSettings {
  const DevotionSettings({
    this.allowLikes = true,
    this.allowReflections = true,
    this.reflectionsPublic = true,
    this.showViews = true,
    this.showAuthor = true,
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

  DevotionSettings copyWith({
    bool? allowLikes,
    bool? allowReflections,
    bool? reflectionsPublic,
    bool? showViews,
    bool? showAuthor,
  }) => DevotionSettings(
    allowLikes: allowLikes ?? this.allowLikes,
    allowReflections: allowReflections ?? this.allowReflections,
    reflectionsPublic: reflectionsPublic ?? this.reflectionsPublic,
    showViews: showViews ?? this.showViews,
    showAuthor: showAuthor ?? this.showAuthor,
  );

  factory DevotionSettings.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data();
    if (d == null) return standard;
    bool flag(String key) => d[key] is bool ? d[key] as bool : true;
    return DevotionSettings(
      allowLikes: flag('allowLikes'),
      allowReflections: flag('allowReflections'),
      reflectionsPublic: flag('reflectionsPublic'),
      showViews: flag('showViews'),
      showAuthor: flag('showAuthor'),
    );
  }

  Map<String, Object> toMap() => {
    'allowLikes': allowLikes,
    'allowReflections': allowReflections,
    'reflectionsPublic': reflectionsPublic,
    'showViews': showViews,
    'showAuthor': showAuthor,
  };

  @override
  bool operator ==(Object other) =>
      other is DevotionSettings &&
      allowLikes == other.allowLikes &&
      allowReflections == other.allowReflections &&
      reflectionsPublic == other.reflectionsPublic &&
      showViews == other.showViews &&
      showAuthor == other.showAuthor;

  @override
  int get hashCode => Object.hash(
    allowLikes,
    allowReflections,
    reflectionsPublic,
    showViews,
    showAuthor,
  );
}
