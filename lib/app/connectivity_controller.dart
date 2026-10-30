import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 인터넷에 연결되어 있는지 지켜본다. 몇 초마다 이름 조회를 해 보고, 실패하면 연결이 없는 것으로 본다.
/// 연결이 돌아오면 바로 [online]이 true가 된다. 웹에서는 지켜보지 않는다 (항상 연결된 것으로 본다).
class ConnectivityController extends ChangeNotifier {
  ConnectivityController({this.interval = const Duration(seconds: 4)}) {
    if (kIsWeb) return;
    _check();
    _timer = Timer.periodic(interval, (_) => _check());
  }

  /// 확인하는 간격.
  final Duration interval;

  Timer? _timer;
  bool _online = true;
  bool _checking = false;

  /// 지금 인터넷에 연결되어 있는가.
  bool get online => _online;

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    var ok = false;
    try {
      final result = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: 3));
      ok = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      ok = false;
    }
    _checking = false;
    if (ok != _online) {
      _online = ok;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
