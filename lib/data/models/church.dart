import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 등록된 교회. 앱 운영자 화면의 교회 등록 관리에서 쓴다.
class Church {
  const Church({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.thumbnailUrl = '',
    this.listed = false,
    this.closed = false,
    this.createdAt,
  });

  final String id;
  final String name;

  /// 교회 전화번호. 앱 운영자가 직접 등록한 교회는 비어 있을 수 있다.
  final String phone;

  /// 도로명 주소.
  final String address;

  /// 교회 썸네일 이미지 주소. 없으면 빈 문자열.
  final String thumbnailUrl;

  /// 공개 탐색에 노출되는가. 노출된 교회는 누구나 찾아서 입장을 요청할 수 있다.
  final bool listed;

  /// 폐쇄된 교회인가. 폐쇄해도 교회와 기록은 지우지 않고 남긴다.
  final bool closed;
  final DateTime? createdAt;

  /// 목록에 보이는 대략의 위치: 시도 시군구까지 (예: "경기 수원시 영통구").
  String get region {
    final t = address.trim().split(RegExp(r'\s+'));
    if (t.length < 2) return address.trim();
    final r = [t[0], t[1]];
    if (t.length > 2 && t[1].endsWith('시') && t[2].endsWith('구')) {
      r.add(t[2]);
    }
    return r.join(' ');
  }

  factory Church.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Church(
      id: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      address: d['address'] as String? ?? '',
      thumbnailUrl: d['thumbnailUrl'] as String? ?? '',
      listed: d['listed'] == true,
      closed: d['closed'] == true,
      createdAt: toDate(d['createdAt']),
    );
  }
}
