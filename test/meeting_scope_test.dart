import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/meeting.dart';
import 'package:god_ch/features/meetings/data/meeting_repository.dart';
import 'package:god_ch/features/meetings/view_model/meetings_view_model.dart';
import 'package:god_ch/features/meetings/view_model/all_meetings_view_model.dart';
import 'package:god_ch/features/meetings/view_model/my_meetings_view_model.dart';

class _Repo extends Fake implements MeetingRepository {
  @override
  Stream<List<Meeting>> latest(String churchId, {int limit = 300}) =>
      const Stream.empty();
}

Meeting _meeting(
  List<String> ids, {
  DateTime? date,
  int capacity = 10,
  List<String> joined = const [],
  String leader = 'l',
  List<String> liked = const [],
}) => Meeting(
  id: 'm',
  title: '모임',
  description: '',
  place: '',
  date: date ?? DateTime(2030),
  capacity: capacity,
  leaderId: leader,
  leaderName: '',
  createdAt: DateTime(2020),
  affiliationIds: ids,
  participantIds: joined,
  likedBy: liked,
);

void main() {
  test('공개 범위가 비어 있으면 모두 참여할 수 있다', () {
    expect(
      _meeting([]).openTo(isStaff: false, affiliationIds: const []),
      isTrue,
    );
  });

  test('여러 소속 중 하나라도 내 소속이면 참여할 수 있다', () {
    final m = _meeting(['a', 'b']);
    expect(m.openTo(isStaff: false, affiliationIds: const ['b']), isTrue);
    expect(m.openTo(isStaff: false, affiliationIds: const ['c']), isFalse);
    expect(m.openTo(isStaff: true, affiliationIds: const []), isTrue);
  });

  test('종료된 모임은 마감 탭에 나오지 않고, 정원이 찬 모임만 마감이다', () {
    final vm = MeetingsViewModel(_Repo(), 'c', '이름');
    final ended = _meeting([], date: DateTime(2020));
    final full = _meeting([], capacity: 2, joined: ['a', 'b']);
    final open = _meeting([]);
    vm.setFilter(MeetingFilter.closed);
    expect(vm.shows(ended), isFalse);
    expect(vm.shows(full), isTrue);
    expect(vm.shows(open), isFalse);
    vm.setFilter(MeetingFilter.all);
    expect(vm.shows(ended), isTrue);
  });

  test('내 일정 관리: 참여 예정 · 관심 일정 · 참여 완료는 한 묶음', () {
    final vm = MyMeetingsViewModel(_Repo(), 'c', 'me');
    final madeEnded = _meeting([], date: DateTime(2020), leader: 'me');
    final madeNext = _meeting([], leader: 'me');
    final joinedNext = _meeting([], joined: ['me']);
    final joinedEnded = _meeting([], date: DateTime(2020), joined: ['me']);
    final likedOnly = _meeting([], liked: ['me']);
    final other = _meeting([]);
    final all = [
      madeEnded,
      madeNext,
      joinedNext,
      joinedEnded,
      likedOnly,
      other,
    ];

    expect(vm.apply(all), [madeNext, joinedNext]);
    vm.setView(MyMeetingView.liked);
    expect(vm.apply(all), [likedOnly]);
    vm.setView(MyMeetingView.attended);
    expect(vm.apply(all), [madeEnded, joinedEnded]);
  });

  test('전체 일정 조회: 범위로 거르고 제목 · 작성자로 검색한다', () {
    final vm = AllMeetingsViewModel(_Repo(), 'c', 'me');
    Meeting m(
      String title,
      String leaderName, {
      String leader = 'x',
      DateTime? date,
      int capacity = 10,
      List<String> joined = const [],
    }) => Meeting(
      id: title,
      title: title,
      description: '',
      place: '',
      date: date ?? DateTime(2030),
      capacity: capacity,
      leaderId: leader,
      leaderName: leaderName,
      createdAt: DateTime(2020),
      participantIds: joined,
    );
    final mineOpen = m('청년 수련회', '김은혜', leader: 'me');
    final mineEnded = m('지난 모임', '김은혜', leader: 'me', date: DateTime(2020));
    final otherFull = m('독서 모임', '박민준', capacity: 2, joined: ['a', 'b']);
    final otherOpen = m('풋살', '박민준');
    final all = [mineOpen, mineEnded, otherFull, otherOpen];

    expect(vm.apply(all).length, 4);
    vm.setOwner(MeetingOwner.mine);
    expect(vm.apply(all).toSet(), {mineOpen, mineEnded});
    vm.setOwner(MeetingOwner.all);

    // 제목으로, 작성자(모임장 이름)로 검색한다.
    vm.setQuery('수련');
    expect(vm.apply(all), [mineOpen]);
    vm.setQuery('박민준');
    expect(vm.apply(all).toSet(), {otherFull, otherOpen});
    vm.setQuery('없는이름');
    expect(vm.apply(all), isEmpty);
  });
}
