import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/view/auth_gate.dart';
import '../features/church/data/church_repository.dart';
import '../features/church/data/department_repository.dart';
import '../features/members/data/member_repository.dart';
import '../features/prayers/data/prayer_repository.dart';
import 'app_scope.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // 저장소는 앱이 살아있는 동안 한 번만 만든다.
  late final AuthRepository _auth = AuthRepository(FirebaseAuth.instance);
  late final ChurchRepository _churches = ChurchRepository(
    FirebaseFirestore.instance,
    _auth,
  );
  late final DepartmentRepository _departments = DepartmentRepository(
    FirebaseFirestore.instance,
    _auth,
  );
  late final MemberRepository _members = MemberRepository(
    FirebaseFirestore.instance,
    _auth,
  );
  late final PrayerRepository _prayers = PrayerRepository(
    FirebaseFirestore.instance,
    _auth,
  );

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: _auth,
      churches: _churches,
      departments: _departments,
      members: _members,
      prayers: _prayers,
      child: MaterialApp(
        title: '함께 기도해요',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
