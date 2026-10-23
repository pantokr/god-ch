import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  /// 오늘 이후의 일정을 가까운 날짜순으로.
  Stream<List<ChurchContent>> upcomingEvents(String churchId, {int? limit}) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    var q = _query(churchId, ContentKind.event)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('date');
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((s) => _map(ContentKind.event, s));
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
  Future<String> uploadImage(
    String churchId,
    ContentKind kind, {
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.length > maxImageBytes) {
      throw const AppException('이미지는 10MB 이하만 올릴 수 있어요.');
    }
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => throw const AppException('JPG, PNG, GIF, WEBP 이미지만 올릴 수 있어요.'),
    };
    // 파일 이름이 겹치지 않도록 시각을 붙인다. 한글 이름은 쓰지 않는다.
    final name = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final ref = _storage.ref('churches/$churchId/${kind.collection}/$name');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
