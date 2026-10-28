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

  CollectionReference<Json> _areas(String churchId) =>
      _paths.church(churchId).collection('contentAreas');

  /// 만들어 둔 영역들 (지운 것은 뺀다).
  Stream<List<ContentArea>> areas(String churchId) => _areas(churchId)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            if (d.data()['deleted'] != true) ?ContentArea.fromDoc(d),
        ],
      );

  /// [kind] 종류에 영역 [name]을 만든다. 같은 종류 안에서 이름이 겹치면 안 된다 ([existing]은 이미 있는 이름들).
  Future<void> addArea(
    String churchId,
    ContentKind kind,
    String name, {
    required Iterable<String> existing,
  }) {
    final n = name.trim();
    if (!kind.hasAreas) throw const AppException('이 종류에는 영역이 없어요.');
    if (n.isEmpty) throw const AppException('영역 이름을 입력해 주세요.');
    if (n.length > ChurchContent.maxCategoryLength) {
      throw const AppException('영역 이름은 20자까지 쓸 수 있어요.');
    }
    if (existing.contains(n)) throw const AppException('이미 있는 영역이에요.');
    return _areas(churchId).add({
      'kind': kind.collection,
      'name': n,
      'createdBy': _auth.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 영역을 지운 것으로 표시한다. 영역 안에 글이 하나라도 남아 있으면 지울 수 없다.
  Future<void> deleteArea(
    String churchId,
    ContentKind kind,
    String name,
  ) async {
    final posts = await _query(
      churchId,
      kind,
    ).where('category', isEqualTo: name).get();
    if (posts.docs.any((d) => d.data()['deleted'] != true)) {
      throw const AppException('영역 안에 게시글이 있어 지울 수 없어요. 먼저 다른 영역으로 옮겨 주세요.');
    }
    final docs = await _areas(churchId)
        .where('kind', isEqualTo: kind.collection)
        .get();
    final batch = _paths.db.batch();
    for (final d in docs.docs) {
      if (d.data()['name'] != name || d.data()['deleted'] == true) continue;
      batch.update(d.reference, {
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });
    }
    await batch.commit();
  }

  /// 글 [items]를 영역 [area]로 옮긴다 (비우면 영역 없음). 한 번에 여러 건도 된다.
  Future<void> moveToArea(
    String churchId,
    List<ChurchContent> items,
    String area,
  ) async {
    final a = area.trim();
    if (a.length > ChurchContent.maxCategoryLength) {
      throw const AppException('영역 이름은 20자까지 쓸 수 있어요.');
    }
    if (items.any((c) => !c.kind.hasAreas)) {
      throw const AppException('이 종류에는 영역이 없어요.');
    }
    for (var i = 0; i < items.length; i += 400) {
      final batch = _paths.db.batch();
      for (final c in items.skip(i).take(400)) {
        batch.update(_paths.contents(churchId, c.kind.collection).doc(c.id), {
          'category': a,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  /// 지워진 글(deleted)은 목록에서 뺀다.
  List<ChurchContent> _map(ContentKind kind, QuerySnapshot<Json> s) => s.docs
      .map((d) => ChurchContent.fromDoc(kind, d))
      .where((c) => !c.deleted)
      .toList();

  /// 날짜가 최근인 순. [limit]이 없으면 전부.
  Stream<List<ChurchContent>> latest(
    String churchId,
    ContentKind kind, {
    int? limit,
  }) {
    var q = _query(churchId, kind).orderBy('date', descending: true);
    // 지워진 글이 섞여 있을 수 있어 조금 더 읽은 뒤 개수를 맞춘다.
    if (limit != null) q = q.limit(limit + 20);
    return q.snapshots().map((s) {
      final items = _map(kind, s);
      return limit == null ? items : items.take(limit).toList();
    });
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
      _paths.contents(churchId, kind.collection).doc(id).snapshots().map((s) {
        if (!s.exists) return null;
        final c = ChurchContent.fromDoc(kind, s);
        return c.deleted ? null : c;
      });

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
    String category = '',
  }) {
    final t = title.trim();
    final cat = category.trim();
    if (cat.length > ChurchContent.maxCategoryLength) {
      throw const AppException('분류는 20자까지 쓸 수 있어요.');
    }
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
      'category': cat,
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

  /// 글을 지운 것으로 표시한다. 글과 함께 올린 이미지도 지우지 않고 그대로 둔다 (기록 보관).
  Future<void> delete(String churchId, ContentKind kind, String id) =>
      _paths.contents(churchId, kind.collection).doc(id).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });

  /// 이미지를 Storage에 올리고 다운로드 주소를 돌려준다.
  /// 휴대폰 사진처럼 큰 이미지는 올리기 전에 긴 변 2048px 이하의 JPEG로 줄인다.
  Future<String> uploadImage(
    String churchId,
    ContentKind kind, {
    required String fileName,
    required Uint8List bytes,
  }) => uploadImageTo(
    'churches/$churchId/${kind.collection}',
    fileName: fileName,
    bytes: bytes,
  );

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

  /// 썸네일(교회 · 회원 사진)의 한 변 길이(px)와 JPEG 품질. 작고 낮은 화질로 저장한다.
  static const thumbnailSize = 256;
  static const thumbnailQuality = 60;

  /// 이미지를 가운데 기준 정사각형으로 잘라 [thumbnailSize]px, 낮은 화질 JPEG로 만들어 [folder]에 올린다.
  Future<String> uploadThumbnailTo(
    String folder, {
    required Uint8List bytes,
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
    final small = side > thumbnailSize
        ? img.copyResize(square, width: thumbnailSize, height: thumbnailSize)
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
