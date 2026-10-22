import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 웹에서 새로고침·재실행 후에도 로그인을 유지한다 (브라우저 저장소 사용).
  if (kIsWeb) await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  runApp(const App());
}
