import 'package:built_in_together/data/models/church_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('유튜브 주소에서 영상 ID를 꺼낸다', () {
    expect(youtubeId('https://www.youtube.com/watch?v=abc123'), 'abc123');
    expect(youtubeId('https://youtu.be/abc123?t=5'), 'abc123');
    expect(youtubeId('https://m.youtube.com/shorts/abc123'), 'abc123');
    expect(youtubeId('https://example.com/watch?v=abc123'), isNull);
    expect(youtubeId('not a url'), isNull);
  });

  test('주소의 이름으로 콘텐츠 종류를 찾는다', () {
    expect(ContentKind.fromPath('sermons'), ContentKind.sermon);
    expect(ContentKind.fromPath('prayers'), isNull);
  });
}
