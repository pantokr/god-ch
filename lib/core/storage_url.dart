/// 이 앱의 Firebase Storage 버킷 (`lib/firebase_options.dart`와 같다).
const kStorageBucket = 'god-ch.firebasestorage.app';

/// 썸네일 · 사진은 이 앱의 Firebase Storage에 있는 것만 쓴다.
/// 로컬 파일이나 외부 주소(다른 사이트, 임의의 URL)는 불러오지 않고 기본 이미지로 둔다.
bool isStorageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  if (uri.host != 'firebasestorage.googleapis.com') return false;
  // /v0/b/{버킷}/o/{경로}
  final s = uri.pathSegments;
  return s.length >= 5 &&
      s[0] == 'v0' &&
      s[1] == 'b' &&
      s[2] == kStorageBucket &&
      s[3] == 'o';
}
