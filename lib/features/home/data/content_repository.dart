import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/church_content.dart';
import '../../auth/data/auth_repository.dart';

/// 교회 메인 페이지 콘텐츠(공지·일정·사진첩·설교·말씀묵상)를 읽고 쓴다.
/// 글은 Firestore에, 이미지는 Firebase Storage(`churches/{id}/{종류}/...`)에 두고
/// 글에는 이미지의 다운로드 주소만 저장한다.
/// 읽기는 승인된 교인, 쓰기는 교역자·교회 운영자만 가능하다
/// (`firestore.rules`와 `storage.rules`가 강제한다).
class ContentRepository {
  ContentRepository(FirebaseFirestore db, this._storage, this._auth)
    : _paths = FirestorePaths(db);

  /// 이미지 한 장의 최대 크기. `storage.rules`의 제한과 같아야 한다.
  static const maxImageBytes = 10 * 1024 * 1024;

  final FirestorePaths _paths;
  final FirebaseStorage _storage;
  final AuthRepository _auth;

  Query<Json> _query(String churchId, ContentKind kind) =>
      _paths.contents(churchId, kind.collection);

  List<ChurchContent> _map(ContentKind kind, QuerySnapshot<Json> s) =>
      s.docs.map((d) => ChurchContent.fromDoc(kind, d)).toList();

  /// 날짜가 최근인 순. [limit]이 없으면 전부.
  Stream<List<ChurchContent>> latest(
    String churchId,
    ContentKind kind, {
    int? limit,
  }) {
    var q = _query(churchId, kind).orderBy('date', descending: true);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((s) => _map(kind, s));
  }

  /// [month]가 속한 달의 일정을 날짜순으로.
  Stream<List<ChurchContent>> eventsInMonth(String churchId, DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _query(churchId, ContentKind.event)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((s) => _map(ContentKind.event, s));
  }

  Stream<ChurchContent?> one(String churchId, ContentKind kind, String id) =>
      _paths
          .contents(churchId, kind.collection)
          .doc(id)
          .snapshots()
          .map((s) => s.exists ? ChurchContent.fromDoc(kind, s) : null);

  /// [id]가 null이면 새로 만들고, 있으면 고친다.
  Future<void> save(
    String churchId,
    ContentKind kind, {
    String? id,
    required String title,
    required String body,
    required DateTime date,
    List<String> imageUrls = const [],
    String videoUrl = '',
  }) {
    final t = title.trim();
    if (t.isEmpty) throw const AppException('제목을 입력해 주세요.');
    if (t.length > 100) throw const AppException('제목은 100자까지 쓸 수 있어요.');
    if (body.trim().length > 5000) {
      throw const AppException('내용은 5000자까지 쓸 수 있어요.');
    }
    final images = imageUrls.map((u) => u.trim()).where((u) => u.isNotEmpty);
    for (final u in images) {
      if (!u.startsWith('https://')) {
        throw const AppException('이미지는 올려서 사용해 주세요.');
      }
    }
    final video = videoUrl.trim();
    if (video.isNotEmpty && youtubeId(video) == null) {
      throw const AppException('유튜브 주소를 입력해 주세요.');
    }
    final data = {
      'title': t,
      'body': body.trim(),
      'date': Timestamp.fromDate(date),
      'imageUrls': images.toList(),
      'videoUrl': video,
    };
    final col = _paths.contents(churchId, kind.collection);
    if (id == null) {
      return col.add({
        ...data,
        'createdBy': _auth.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 글을 지우고, 함께 올렸던 이미지도 Storage에서 지운다.
  Future<void> delete(String churchId, ContentKind kind, String id) async {
    final ref = _paths.contents(churchId, kind.collection).doc(id);
    final urls = List<String>.from(
      (await ref.get()).data()?['imageUrls'] as List? ?? const [],
    );
    await ref.delete();
    for (final url in urls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        // 이미 없거나 이 교회의 파일이 아니면 건너뛴다. 글은 이미 지워졌다.
      }
    }
  }

  /// 이미지를 Storage에 올리고 다운로드 주소를 돌려준다.
  /// 휴대폰 사진처럼 큰 이미지는 올리기 전에 긴 변 2048px 이하의 JPEG로 줄인다.
  Future<String> uploadImage(
    String churchId,
    ContentKind kind, {
    required String fileName,
    required Uint8List bytes,
  }) async {
    var data = bytes;
    var ext = _imageExtension(bytes, fileName);
    if (ext == null) {
      throw const AppException(
        'JPG, PNG, GIF, WEBP 이미지만 올릴 수 있어요. (아이폰 HEIC 사진은 카메라 설정에서 "호환성 우선"으로 찍거나 JPG로 바꿔 주세요.)',
      );
    }
    if (ext != 'gif' && bytes.length > resizeAboveBytes) {
      final shrunk = _shrink(bytes);
      if (shrunk != null) {
        data = shrunk;
        ext = 'jpg';
      }
    }
    if (data.length > maxImageBytes) {
      throw const AppException('이미지는 10MB 이하만 올릴 수 있어요.');
    }
    final contentType = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    // 파일 이름이 겹치지 않도록 시각을 붙인다. 한글 이름은 쓰지 않는다.
    final name = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final ref = _storage.ref('churches/$churchId/${kind.collection}/$name');
    await ref.putData(data, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// 이 크기를 넘는 이미지는 올리기 전에 줄인다.
  static const resizeAboveBytes = 2 * 1024 * 1024;

  /// 파일 내용으로 이미지 종류를 알아낸다 (휴대폰에서 고른 파일은 이름에 확장자가 없을 수 있다).
  /// 지원하지 않는 형식(HEIC 등)이면 null.
  static String? _imageExtension(Uint8List b, String fileName) {
    bool starts(List<int> sig, [int at = 0]) {
      if (b.length < at + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[at + i] != sig[i]) return false;
      }
      return true;
    }

    if (starts([0xFF, 0xD8, 0xFF])) return 'jpg';
    if (starts([0x89, 0x50, 0x4E, 0x47])) return 'png';
    if (starts([0x47, 0x49, 0x46, 0x38])) return 'gif';
    if (starts([0x52, 0x49, 0x46, 0x46]) &&
        starts([0x57, 0x45, 0x42, 0x50], 8)) {
      return 'webp';
    }
    return null;
  }

  /// 긴 변이 2048px을 넘지 않는 JPEG로 줄인다. 해석하지 못하면 null (원본 그대로 올린다).
  static Uint8List? _shrink(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      final longest = image.width > image.height ? image.width : image.height;
      final resized = longest > 2048
          ? img.copyResize(
              image,
              width: image.width >= image.height ? 2048 : null,
              height: image.height > image.width ? 2048 : null,
            )
          : image;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return null;
    }
  }
}
