import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'member.dart';

/// 교회 사람 목록에 보이는 최소한의 정보. `churches/{id}/people/{uid}`에 저장된다.
/// 교인 문서(`members`)에는 전화번호 · 주소 같은 개인정보가 있어 교역자만 읽을 수 있으므로,
/// 모든 교인이 볼 수 있는 이름 · 사진 · 역할 · 소속 · 생일(월-일)만 따로 복사해 둔다.
/// 교인 문서가 바뀔 때마다 [mirrorPersonCard]가 맞춰 쓴다.
class PersonCard {
  const PersonCard({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.photoUrl = '',
    this.affiliationIds = const [],
    this.birthMonthDay = '',
  });

  final String id;
  final String name;
  final String photoUrl;
  final Role role;
  final MemberStatus status;
  final List<String> affiliationIds;

  /// 생일의 월-일 ("MM-DD"). 생년월일을 내지 않았으면 빈 문자열이다 (출생 연도는 저장하지 않는다).
  final String birthMonthDay;

  bool get isApproved => status == MemberStatus.approved;

  /// 생일의 달 (1~12). 없으면 null.
  int? get birthMonth => birthMonthDay.length == 5
      ? int.tryParse(birthMonthDay.substring(0, 2))
      : null;

  /// 생일의 날 (1~31). 없으면 null.
  int? get birthDay => birthMonthDay.length == 5
      ? int.tryParse(birthMonthDay.substring(3, 5))
      : null;

  factory PersonCard.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return PersonCard(
      id: doc.id,
      name: d['name'] as String? ?? '',
      photoUrl: d['photoUrl'] as String? ?? '',
      role: enumByName(Role.values, d['role'], Role.member),
      status: enumByName(
        MemberStatus.values,
        d['status'],
        MemberStatus.pending,
      ),
      affiliationIds: List<String>.from(
        d['affiliationIds'] as List? ?? const [],
      ),
      birthMonthDay: d['birthMonthDay'] as String? ?? '',
    );
  }
}
