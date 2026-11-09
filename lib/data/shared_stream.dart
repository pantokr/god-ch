import 'dart:async';

/// 같은 조회를 여러 곳이 동시에 듣거나 화면이 다시 그려질 때마다 새로 듣는 일을 막는다.
/// 같은 키의 스트림은 서버 구독을 하나만 만들어 나눠 쓰고, 새로 듣는 쪽에는 가장 최근 값을 바로 준다.
/// 듣는 곳이 모두 사라져도 [grace] 동안은 구독을 유지해, 화면을 오가거나 목록이 다시 그려져도 다시 읽지 않는다.
///
/// 목록 카드마다 반응 · 댓글 수를 따로 듣거나, 여러 화면이 교인 목록 · 운영 설정을 각자 듣는 곳에 쓴다.
/// 키에는 조회 결과가 달라지는 조건(교회 · 글 · 로그인한 사람)을 모두 넣는다.
class SharedStreams {
  SharedStreams({this.grace = const Duration(seconds: 10)});

  final Duration grace;
  final _entries = <Object, _Shared<Object?>>{};

  /// 서버 구독 수 (시험용).
  int get active => _entries.length;

  Stream<T> of<T>(Object key, Stream<T> Function() source) =>
      Stream<T>.multi((controller) {
        final entry = (_entries[key] ??= _Shared<Object?>(
          () => source() as Stream<Object?>,
          grace,
          () => _entries.remove(key),
        ));
        entry.attach(controller as MultiStreamController<Object?>);
      }, isBroadcast: true);
}

class _Shared<T> {
  _Shared(this._source, this._grace, this._onDispose);

  final Stream<T> Function() _source;
  final Duration _grace;
  final void Function() _onDispose;

  final _listeners = <MultiStreamController<T>>{};
  StreamSubscription<T>? _sub;
  Timer? _timer;
  bool _hasValue = false;
  T? _last;

  void attach(MultiStreamController<T> c) {
    _timer?.cancel();
    _timer = null;
    _listeners.add(c);
    if (_hasValue) c.add(_last as T);
    c.onCancel = () {
      _listeners.remove(c);
      if (_listeners.isEmpty) {
        _timer = Timer(_grace, _dispose);
      }
    };
    _sub ??= _source().listen(
      (v) {
        _hasValue = true;
        _last = v;
        for (final l in [..._listeners]) {
          l.addSync(v);
        }
      },
      onError: (Object e, StackTrace s) {
        for (final l in [..._listeners]) {
          l.addErrorSync(e, s);
        }
      },
    );
  }

  void _dispose() {
    _timer = null;
    if (_listeners.isNotEmpty) return;
    _sub?.cancel();
    _sub = null;
    _onDispose();
  }
}
