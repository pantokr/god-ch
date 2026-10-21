import 'package:cloud_firestore/cloud_firestore.dart';

typedef Json = Map<String, dynamic>;

/// 문서에 저장된 이름으로 enum 값을 찾는다. 없으면 [fallback].
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

/// Firestore Timestamp를 DateTime으로. 서버 시각이 아직 확정되지 않았으면 null.
DateTime? toDate(Object? value) => value is Timestamp ? value.toDate() : null;
