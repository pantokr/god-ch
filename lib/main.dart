import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'app/list_style_controller.dart';
import 'app/theme_mode_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 웹에서 새로고침·재실행 후에도 로그인을 유지한다 (브라우저 저장소 사용).
  if (kIsWeb) await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  // 저장된 화면 모드를 먼저 불러와 첫 화면부터 맞는 모드로 그린다.
  final themeMode = await ThemeModeController.load();
  final listStyle = await ListStyleController.load();
  // 광고(앱 종료 확인 창)는 켜 두고 기다리지 않는다. 웹에서는 쓰지 않는다.
  if (!kIsWeb) {
    try {
      MobileAds.instance.initialize().then((_) {}, onError: (_) {});
    } catch (_) {}
  }
  runApp(App(themeMode: themeMode, listStyle: listStyle));
}
