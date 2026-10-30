import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_settings.dart';
import '../../auth/data/auth_repository.dart';

/// 말씀묵상 글을 읽고 쓴다. 이미지 올리기(교회 · 회원 사진)도 여기서 한다.
/// 읽기는 승인된 교인, 글쓰기는 교역자 · 교회 운영자만 가능하다 (`firestore.rules`가 강제한다).
class ContentRepository {
  ContentRepository(FirebaseFirestore db, this._storage, this._auth)
    : _paths = FirestorePaths(db);

  /// 이미지 한 장의 최대 크기. `storage.rules`의 제한과 같아야 한다.
  static const maxImageBytes = 10 * 1024 * 1024;

  final FirestorePaths _paths;
  final FirebaseStorage _storage;
  final AuthRepository _auth;

  CollectionReference<Json> _col(String churchId) => _paths.devotions(churchId);

  DocumentReference<Json> _settings(String churchId) =>
      _paths.church(churchId).collection('settings').doc('devotion');

  /// 교회가 정한 말씀묵상 운영 설정. 정한 적 없으면 표준 설정이다.
  Stream<DevotionSettings> settings(String churchId) =>
      _settings(churchId).snapshots().map(DevotionSettings.fromDoc);

  Future<DevotionSettings> loadSettings(String churchId) async =>
      DevotionSettings.fromDoc(await _settings(churchId).get());

  Future<void> saveSettings(String churchId, DevotionSettings settings) =>
      _settings(churchId).set(settings.toMap());

  /// 날짜가 최근인 순. 지워진 글은 뺀다.
  Stream<List<ChurchContent>> latest(
    String churchId, {
    int limit = 30,
    bool includePrivate = false,
  }) {
    // 비공개 글을 볼 수 없는 사람은 공개 글만 묻는다 (규칙이 비공개 글이 섞인 조회를 막는다).
    // 이 경우 서버 정렬이 없어 최근 글을 화면에서 가려낸다.
    final query = includePrivate
        ? _col(churchId).orderBy('date', descending: true).limit(limit + 20)
        : _col(churchId).where('visibility', isEqualTo: 'public').limit(300);
    return query.snapshots().map((s) {
      final list =
          [
              for (final d in s.docs)
                ChurchContent.fromDoc(ContentKind.devotion, d),
            ].where((c) => !c.deleted).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      return list.take(limit).toList();
    });
  }

  /// 글 한 건. 지워졌거나 없으면 null.
  Stream<ChurchContent?> one(String churchId, String id) =>
      _col(churchId).doc(id).snapshots().map((s) {
        if (!s.exists) return null;
        final c = ChurchContent.fromDoc(ContentKind.devotion, s);
        return c.deleted ? null : c;
      });

  /// 내가 이 글을 읽었다고 남긴다 (목록의 읽음 표시). 이미 남았으면 그대로다.
  Future<void> markRead(String churchId, String id) =>
      _col(churchId).doc(id).update({
        'readBy': FieldValue.arrayUnion([_auth.uid]),
      });

  /// 조회수를 하나 올린다 (글을 열 때마다). 규칙이 +1만 허용한다.
  Future<void> addView(String churchId, String id) =>
      _col(churchId).doc(id).update({'views': FieldValue.increment(1)});

  /// 좋아요를 누르거나 취소한다. 누른 사람의 uid가 [ChurchContent.likedBy]에 담긴다.
  Future<void> setLike(String churchId, String id, {required bool liked}) =>
      _col(churchId).doc(id).update({
        'likedBy': liked
            ? FieldValue.arrayUnion([_auth.uid])
            : FieldValue.arrayRemove([_auth.uid]),
      });

  /// [id]가 null이면 새로 만들고, 있으면 고친다.
  Future<void> save(
    String churchId, {
    String? id,
    required String title,
    required String body,
    required String meditation,
    required DateTime date,
    String authorName = '',
    String authorPhotoUrl = '',
    String? affiliationId,
    bool isPrivate = false,
  }) {
    final t = title.trim();
    if (t.isEmpty) throw const AppException('제목을 입력해 주세요.');
    if (t.length > 100) throw const AppException('제목은 100자까지 쓸 수 있어요.');
    if (body.trim().length > 5000) {
      throw const AppException('내용은 5000자까지 쓸 수 있어요.');
    }
    if (meditation.trim().length > 5000) {
      throw const AppException('묵상은 5000자까지 쓸 수 있어요.');
    }
    final data = {
      'title': t,
      'body': body.trim(),
      'meditation': meditation.trim(),
      'date': Timestamp.fromDate(date),
      'affiliationId': affiliationId,
      'visibility': isPrivate ? 'private' : 'public',
    };
    if (id == null) {
      return _col(churchId).add({
        ...data,
        'views': 0,
        'likedBy': <String>[],
        'createdBy': _auth.uid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return _col(churchId)
        .doc(id)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// 글을 지운 것으로 표시한다 (기록 보관).
  Future<void> delete(String churchId, String id) => _col(churchId)
      .doc(id)
      .update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });

  /// [folder] 아래에 이미지를 올린다 (교회 썸네일 · 회원 사진 등). 검사와 줄이기는 [uploadImage]와 같다.
  Future<String> uploadImageTo(
    String folder, {
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
    final ref = _storage.ref('$folder/$name');
    await ref.putData(data, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// Storage 파일의 내려받기 주소. 파일이 없거나 읽을 수 없으면 null.
  Future<String?> downloadUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } on FirebaseException {
      return null;
    }
  }

  /// 썸네일(교회 · 회원 사진)의 한 변 길이(px)와 JPEG 품질. 작고 낮은 화질로 저장한다.
  static const thumbnailSize = 256;
  static const thumbnailQuality = 60;

  /// 이미지를 가운데 기준 정사각형으로 잘라 [thumbnailSize]px, 낮은 화질 JPEG로 만들어 [folder]에 올린다.
  Future<String> uploadThumbnailTo(
    String folder, {
    required Uint8List bytes,
    int size = thumbnailSize,
  }) async {
    if (_imageExtension(bytes, '') == null) {
      throw const AppException(
        'JPG, PNG, GIF, WEBP 이미지만 올릴 수 있어요. (아이폰 HEIC 사진은 JPG로 바꿔 주세요.)',
      );
    }
    final image = img.decodeImage(bytes);
    if (image == null) throw const AppException('이미지를 읽지 못했어요.');
    final side = image.width < image.height ? image.width : image.height;
    final square = img.copyCrop(
      image,
      x: (image.width - side) ~/ 2,
      y: (image.height - side) ~/ 2,
      width: side,
      height: side,
    );
    final small = side > size
        ? img.copyResize(square, width: size, height: size)
        : square;
    final data = Uint8List.fromList(
      img.encodeJpg(small, quality: thumbnailQuality),
    );
    final name = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref('$folder/$name');
    await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
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
