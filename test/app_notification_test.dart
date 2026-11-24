import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/app_notification.dart';

AppNotification _n(String title) => AppNotification(
  id: 'a',
  title: title,
  body: '',
  type: NotificationType.general,
  read: false,
);

void main() {
  test('유형 · 이름 꼴의 제목은 둘로 나뉜다', () {
    expect(_n('댓글 · 새벽기도').titleParts, ('댓글', '새벽기도'));
    expect(_n('참여 신청 · 등산 · 모임').titleParts, ('참여 신청', '등산 · 모임'));
  });

  test('구분이 없는 제목은 나뉘지 않는다', () {
    expect(_n('문의에 답변이 달렸어요').titleParts, isNull);
    expect(_n(' · 이름').titleParts, isNull);
  });
}
