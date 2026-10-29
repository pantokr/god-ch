import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/firestore_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../prayers/data/prayer_repository.dart';

/// 화면을 확인할 수 있게 기도제목 · 말씀 · 모임 견본을 한꺼번에 넣는다 (교회 운영자가 누른다).
/// 보안 규칙을 그대로 지킨다: 교역자는 견본에 한해 조회수 · 좋아요 · 참여자를 미리 채워 만들 수 있다.
class SampleDataRepository {
  SampleDataRepository(FirebaseFirestore db, this._auth)
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;

  static final _random = Random();

  /// 가짜 교인 uid 목록 (좋아요 · 참여자 수를 채우는 데만 쓴다).
  static List<String> _fans(int n) => [for (var i = 0; i < n; i++) 'sample-$i'];

  /// 견본을 넣고 (기도제목, 말씀, 모임) 개수를 돌려준다.
  Future<({int prayers, int devotions, int meetings})> seed(
    String churchId,
  ) async {
    final uid = _auth.uid;
    final now = DateTime.now();
    final batch = _db.batch();

    // ---- 기도제목 ----
    const prayers = [
      ('건강을 위한 기도', '수술을 앞둔 가족이 있습니다. 회복의 시간 동안 평안과 담대함을 허락해 주세요.'),
      ('새 직장을 위한 기도', '이번 달 면접이 세 번 있습니다. 좋은 만남과 분별의 지혜를 구합니다.'),
      ('시험을 앞둔 청년부', '기말 시험과 취업 준비로 지친 지체들이 쉼과 힘을 얻도록 기도해 주세요.'),
      ('교회학교 여름 캠프', '안전하고 은혜로운 캠프가 되도록, 교사들의 섬김이 기쁨이 되도록 기도합니다.'),
      ('다툰 가정의 화해', '오래 마음이 닫힌 가족과 대화의 문이 열리기를 간구합니다.'),
      ('선교지의 동역자', '현지 사역자의 건강과 안전, 필요한 재정이 채워지도록 중보해 주세요.'),
      ('마음의 평안', '이유 없이 불안한 날들이 이어집니다. 주님의 평안이 임하도록 기도 부탁드립니다.'),
      ('감사 기도', '오랜 기도 끝에 이사할 집이 구해졌습니다. 함께 감사해 주세요!'),
    ];
    for (var i = 0; i < prayers.length; i++) {
      batch.set(_paths.prayers(churchId).doc(PrayerRepository.newId()), {
        'authorId': uid,
        'title': prayers[i].$1,
        'content': prayers[i].$2,
        'visibility': 'public',
        'deleted': false,
        'views': 8 + _random.nextInt(120),
        'createdAt': Timestamp.fromDate(now.subtract(Duration(days: i))),
        'updatedAt': Timestamp.fromDate(now.subtract(Duration(days: i))),
      });
    }

    // ---- 말씀 묵상 ----
    const devotions = [
      (
        '시편 23:1-3',
        '여호와는 나의 목자시니 내가 부족함이 없으리로다. 그가 나를 푸른 풀밭에 누이시며 쉴 만한 물가로 인도하시는도다. 내 영혼을 소생시키시고 자기 이름을 위하여 의의 길로 인도하시는도다.',
        '부족함이 없다는 고백은 가진 것이 많아서가 아니라 목자가 곁에 계시기 때문입니다. 오늘 쉼이 필요한 자리가 어디인지 주님께 맡겨 보세요.',
      ),
      (
        '빌립보서 4:6-7',
        '아무 것도 염려하지 말고 다만 모든 일에 기도와 간구로, 너희 구할 것을 감사함으로 하나님께 아뢰라. 그리하면 모든 지각에 뛰어난 하나님의 평강이 그리스도 예수 안에서 너희 마음과 생각을 지키시리라.',
        '염려를 기도로 바꾸는 연습입니다. 걱정이 떠오를 때마다 한 문장 기도로 올려 드립시다.',
      ),
      (
        '잠언 3:5-6',
        '너는 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라. 너는 범사에 그를 인정하라 그리하면 네 길을 지도하시리라.',
        '내가 아는 만큼만 걷지 않고, 모르는 길도 맡기고 걷는 한 주가 되길 바랍니다.',
      ),
      (
        '이사야 41:10',
        '두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라 내가 너를 굳세게 하리라 참으로 너를 도와 주리라.',
        '두려움 앞에서 먼저 기억할 것은 함께하심입니다. 이번 주 두려운 일 하나를 적어 두고 이 말씀으로 기도해 봅시다.',
      ),
      (
        '요한복음 3:16',
        '하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라.',
        '사랑은 말이 아니라 주신 것으로 증명되었습니다. 내가 받은 사랑을 누군가에게 흘려보낼 한 가지를 정해 봅니다.',
      ),
      (
        '로마서 8:28',
        '우리가 알거니와 하나님을 사랑하는 자 곧 그의 뜻대로 부르심을 입은 자들에게는 모든 것이 합력하여 선을 이루느니라.',
        '지금 이해되지 않는 일도 선으로 엮어 가신다는 약속입니다. 기다림의 시간을 믿음으로 지나가 봅시다.',
      ),
      (
        '마태복음 11:28',
        '수고하고 무거운 짐 진 자들아 다 내게로 오라 내가 너희를 쉬게 하리라.',
        '쉼은 초대입니다. 오늘 내려놓고 싶은 짐을 구체적으로 한 줄 써서 주님께 가져가세요.',
      ),
      (
        '여호수아 1:9',
        '내가 네게 명령한 것이 아니냐 강하고 담대하라 두려워하지 말며 놀라지 말라 네가 어디로 가든지 네 하나님 여호와가 너와 함께 하느니라 하시니라.',
        '담대함은 내 힘이 아니라 함께하시는 분에게서 옵니다. 이번 주 피하고 싶던 일을 한 걸음만 시작해 봅시다.',
      ),
    ];
    for (var i = 0; i < devotions.length; i++) {
      batch.set(_paths.contents(churchId, 'devotions').doc(), {
        'title': devotions[i].$1,
        'body': devotions[i].$2,
        'meditation': devotions[i].$3,
        'date': Timestamp.fromDate(now.subtract(Duration(days: i * 2))),
        'views': 20 + _random.nextInt(200),
        'likedBy': _fans(3 + _random.nextInt(18)),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // ---- 모임 ----
    // (제목, 모임장, 소개, 장소, 며칠 뒤(음수면 지난 모임), 정원, 참여 인원)
    final meetings = [
      (
        '심야반점 - 깊은 마라요리와 따뜻한 사람들',
        '앵콜 모임장',
        '마라탕과 꿔바로우를 나누며 이야기하는 저녁 모임입니다. 처음 오시는 분도 환영해요!',
        '서대문',
        3,
        8,
        7,
      ),
      (
        '목요일 저녁, 속마음식탁',
        '김은혜',
        '포트럭으로 음식을 나누고 기도제목을 나누는 시간입니다. 가볍게 먹을 것 하나만 가져오세요.',
        '플카페 C동 205호',
        5,
        12,
        9,
      ),
      (
        '주말 풋살 PLFC',
        '박민준',
        '토요일 아침 가볍게 뛰는 풋살 모임입니다. 초보자도 괜찮아요. 운동화만 챙겨 오세요.',
        '노들나루 풋살장',
        9,
        14,
        14,
      ),
      (
        '영화를 보고 세상을 말하다',
        '이서연',
        '같은 영화를 보고 와서 각자의 생각을 나누는 독서 토론형 영화 모임입니다.',
        '청년부실',
        12,
        10,
        4,
      ),
      (
        '보드게임 주중모임',
        '최하준',
        '고혈압 주의! 가볍게 어울리는 보드게임 저녁입니다. 선착순 마감.',
        '플카페',
        16,
        8,
        5,
      ),
      (
        '러닝 뛰뛰빵빵',
        '정다은',
        '주 1회 한강 러닝 크루. 왕초보부터 숙련자까지 함께 뛰어요.',
        '2층 플라운지',
        20,
        20,
        6,
      ),
      (
        '지난 영화모임 시즌1',
        '이서연',
        '사랑을 보고 사랑을 말하다. 시즌1이 끝났습니다. 시즌2에서 만나요.',
        '웨슬리홀',
        -10,
        10,
        10,
      ),
    ];
    for (final m in meetings) {
      final when = DateTime(
        now.year,
        now.month,
        now.day,
        19,
        30,
      ).add(Duration(days: m.$5));
      batch.set(_paths.church(churchId).collection('meetings').doc(), {
        'title': m.$1,
        'description': m.$3,
        'place': m.$4,
        'date': Timestamp.fromDate(when),
        'capacity': m.$6,
        'leaderId': uid,
        'leaderName': m.$2,
        'participantIds': [uid, ..._fans(m.$7 - 1)],
        'likedBy': _fans(2 + _random.nextInt(25)),
        'views': 15 + _random.nextInt(150),
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return (
      prayers: prayers.length,
      devotions: devotions.length,
      meetings: meetings.length,
    );
  }
}
