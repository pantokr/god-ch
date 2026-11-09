import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/shared_stream.dart';

void main() {
  test('같은 키는 서버 구독을 하나만 만들고 새로 듣는 쪽에 최근 값을 바로 준다', () async {
    final shared = SharedStreams(grace: const Duration(milliseconds: 30));
    var opened = 0;
    final source = StreamController<int>.broadcast();
    Stream<int> make() {
      opened++;
      return source.stream;
    }

    final a = <int>[];
    final b = <int>[];
    final subA = shared.of('k', make).listen(a.add);
    source.add(1);
    await Future<void>.delayed(Duration.zero);
    final subB = shared.of('k', make).listen(b.add);
    await Future<void>.delayed(Duration.zero);
    source.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(opened, 1);
    expect(a, [1, 2]);
    expect(b, [1, 2]); // 늦게 들어온 쪽도 최근 값(1)부터 받는다.

    // 모두 떠나도 잠깐은 구독을 유지하고, 그 사이 다시 들으면 새로 열지 않는다.
    await subA.cancel();
    await subB.cancel();
    expect(shared.active, 1);
    final c = <int>[];
    final subC = shared.of('k', make).listen(c.add);
    await Future<void>.delayed(Duration.zero);
    expect(opened, 1);
    expect(c, [2]);
    await subC.cancel();

    // 유예가 지나면 구독을 닫는다.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(shared.active, 0);
    expect(source.hasListener, isFalse);
    await source.close();
  });

  test('키가 다르면 따로 구독한다', () async {
    final shared = SharedStreams(grace: const Duration(milliseconds: 10));
    var opened = 0;
    Stream<int> make() {
      opened++;
      return Stream.value(opened);
    }

    final x = await shared.of('x', make).first;
    final y = await shared.of('y', make).first;
    expect(opened, 2);
    expect(x != y, isTrue);
  });
}
