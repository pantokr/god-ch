import 'package:flutter/material.dart';

/// 페이지 메뉴에 쓸 수 있는 아이콘. 키는 Firestore에 저장되는 이름이다.
class PageIcon {
  const PageIcon(this.label, this.outlined, this.filled);

  final String label;
  final IconData outlined;
  final IconData filled;
}

const pageIcons = <String, PageIcon>{
  'home': PageIcon('집', Icons.home_outlined, Icons.home),
  'book': PageIcon('말씀', Icons.menu_book_outlined, Icons.menu_book),
  'favorite': PageIcon('하트', Icons.favorite_border, Icons.favorite),
  'campaign': PageIcon('소식', Icons.campaign_outlined, Icons.campaign),
  'event': PageIcon('일정', Icons.event_outlined, Icons.event),
  'photo': PageIcon('사진', Icons.photo_library_outlined, Icons.photo_library),
  'video': PageIcon('영상', Icons.smart_display_outlined, Icons.smart_display),
  'groups': PageIcon('모임', Icons.groups_outlined, Icons.groups),
  'church': PageIcon('교회', Icons.church_outlined, Icons.church),
  'star': PageIcon('별', Icons.star_border, Icons.star),
  'chat': PageIcon('대화', Icons.chat_bubble_outline, Icons.chat_bubble),
};

PageIcon pageIconOf(String key) => pageIcons[key] ?? pageIcons['home']!;
