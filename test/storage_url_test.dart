import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/storage_url.dart';

void main() {
  test('Storage 주소만 썸네일로 쓴다', () {
    expect(
      isStorageUrl(
        'https://firebasestorage.googleapis.com/v0/b/god-ch.firebasestorage.app/o/a%2Fb.jpg?alt=media&token=t',
      ),
      isTrue,
    );
    expect(isStorageUrl(null), isFalse);
    expect(isStorageUrl(''), isFalse);
    expect(isStorageUrl('https://picsum.photos/200'), isFalse);
    expect(
      isStorageUrl(
        'http://firebasestorage.googleapis.com/v0/b/god-ch.firebasestorage.app/o/a',
      ),
      isFalse,
    );
    expect(
      isStorageUrl(
        'https://firebasestorage.googleapis.com/v0/b/other-bucket/o/a',
      ),
      isFalse,
    );
    expect(isStorageUrl('assets/images/x.png'), isFalse);
  });
}
