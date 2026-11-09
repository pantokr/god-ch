import 'package:flutter/material.dart';

import '../../../core/widgets/role_chips.dart';

/// 글의 소속을 보이는 표시 (예: 청년회). 어디서나 같은 소속 모양([AffiliationChip])이다.
class AffiliationTag extends StatelessWidget {
  const AffiliationTag(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) => AffiliationChip(name, compact: true);
}

/// 글의 소속 표시 문구: 소속이 없으면(교회 전체 공개) "전체", 있으면 소속 이름. 이름을 아직 모르면 null.
String? affiliationLabel(Map<String, String> names, String? affiliationId) =>
    affiliationId == null ? '전체' : names[affiliationId];
