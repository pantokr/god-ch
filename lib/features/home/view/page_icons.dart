import '../../../core/icons.dart';

import 'package:flutter/material.dart';

/// 페이지 메뉴에 쓸 수 있는 아이콘. 키는 Firestore에 저장되는 이름이다.
class PageIcon {
  const PageIcon(this.label, this.outlined, this.filled);

  final String label;
  final IconData outlined;
  final IconData filled;
}

const pageIcons = <String, PageIcon>{
  'home': PageIcon('집', AppIcons.house, AppIcons.houseFill),
  'book': PageIcon('말씀', AppIcons.bookOpen, AppIcons.bookOpenFill),
  'favorite': PageIcon('하트', AppIcons.heart, AppIcons.heartFill),
  'campaign': PageIcon('소식', AppIcons.megaphone, AppIcons.megaphoneFill),
  'event': PageIcon('일정', AppIcons.calendarBlank, AppIcons.calendarBlankFill),
  'photo': PageIcon('사진', AppIcons.images, AppIcons.imagesFill),
  'video': PageIcon('영상', AppIcons.monitorPlay, AppIcons.monitorPlayFill),
  'groups': PageIcon('모임', AppIcons.usersThree, AppIcons.usersThreeFill),
  'church': PageIcon('교회', AppIcons.church, AppIcons.churchFill),
  'star': PageIcon('별', AppIcons.star, AppIcons.starFill),
  'chat': PageIcon('대화', AppIcons.chatCircle, AppIcons.chatCircleFill),
};

PageIcon pageIconOf(String key) => pageIcons[key] ?? pageIcons['home']!;
