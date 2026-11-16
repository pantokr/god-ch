import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/inquiry.dart';
import 'package:god_ch/features/inquiry/data/inquiry_repository.dart';
import 'package:god_ch/features/inquiry/view_model/inquiry_view_models.dart';

class _Repo extends Fake implements InquiryRepository {
  @override
  Stream<List<Inquiry>> mine({int limit = 100}) => const Stream.empty();

  @override
  Stream<List<Inquiry>> all({int limit = 200}) => const Stream.empty();
}

Inquiry _item(String id, {String answer = ''}) => Inquiry(
  id: id,
  uid: 'u',
  userName: '김성도',
  title: '제목 $id',
  message: '내용',
  answer: answer,
);

void main() {
  test('답변이 있으면 답변 완료다', () {
    expect(_item('1').answered, isFalse);
    expect(_item('2', answer: '확인했어요').answered, isTrue);
  });

  test('운영자 화면은 답변 상태로 거른다', () {
    final vm = InquiryAdminViewModel(_Repo());
    final all = [_item('1'), _item('2', answer: '답'), _item('3')];
    expect(vm.apply(all).length, 3);
    vm.setAnswered(false);
    expect([for (final i in vm.apply(all)) i.id], ['1', '3']);
    vm.setAnswered(true);
    expect([for (final i in vm.apply(all)) i.id], ['2']);
    vm.dispose();
  });

  test('길이 제한이 firestore.rules와 같다', () {
    final rules = File('firestore.rules').readAsStringSync();
    final start = rules.indexOf('match /inquiries/');
    expect(start, greaterThan(0), reason: '규칙에 inquiries가 있어야 한다');
    final block = rules.substring(start, rules.indexOf('match /admins/'));
    expect(block, contains('title.size() <= ${Inquiry.maxTitle}'));
    expect(block, contains('message.size() <= ${Inquiry.maxMessage}'));
    expect(block, contains('answer.size() <= ${Inquiry.maxAnswer}'));
  });
}
