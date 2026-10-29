import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../church/data/admin_affiliations.dart' as admin_affs;
import '../../../data/models/app_notification.dart';
import '../../../data/models/blocked_user.dart';
import '../../../data/models/member.dart';
import '../../auth/data/auth_repository.dart';

/// 교회별 교인 목록과 승인·역할 변경.
class MemberRepository {
  MemberRepository(FirebaseFirestore db, this._auth)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

  /// 이 교회의 교인들. 추방된 사람과 앱 운영자(admin 계정)는 교인이 아니므로 뺀다.
  Stream<List<Member>> members(String churchId) async* {
    // 앱 운영자로 로그인한 사람은 자기 문서가 남아 있어도 교인으로 보이지 않는다.
    final operatorUid = await _auth.hasOperatorClaim() ? _auth.uid : null;
    yield* _paths
        .members(churchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(Member.fromDoc)
              .where(
                (m) =>
                    m.status != MemberStatus.removed &&
                    !m.isAppOperator &&
                    m.id != operatorUid,
              )
              .toList(),
        );
  }

  /// 승인을 기다리는 입장 요청 수.
  Stream<int> pendingCount(String churchId) => _paths
      .members(churchId)
      .where('status', isEqualTo: MemberStatus.pending.name)
      .snapshots()
      .map((s) => s.size);

  /// 교인을 교회에서 내보낸다 (교회 운영자만, 규칙이 강제한다).
  /// 당사자에게는 알림이 간다 (추방과 한 묶음으로 쓴다).
  Future<void> remove(String churchId, String churchName, String userId) =>
      _removeAndNotify(
        churchId,
        userId,
        '$churchName 교회에서 추방되었어요',
        '다시 들어오려면 초대 코드로 새로 신청해야 해요.',
      );

  /// 내가 이 교회에서 탈퇴한다. 교인 문서는 지우지 않고 removed 표시만 남긴다 (규칙이 강제한다).
  Future<void> leave(String churchId) =>
      _paths.members(churchId).doc(_auth.uid).update({
        'status': MemberStatus.removed.name,
        'removedAt': FieldValue.serverTimestamp(),
        'removedBy': _auth.uid,
      });

  Future<void> _removeAndNotify(
    String churchId,
    String userId,
    String title,
    String body, {
    Map<String, dynamic>? block,
  }) {
    final batch = _paths.db.batch();
    batch.set(
      _paths.db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(),
      {
        'type': NotificationType.churchRemoved.name,
        'title': title,
        'body': body,
        'read': false,
        'churchId': churchId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    if (block != null) batch.set(_paths.blocked(churchId).doc(userId), block);
    // 교인 문서는 지우지 않고 추방(removed) 표시만 남긴다.
    batch.update(_paths.members(churchId).doc(userId), {
      'status': MemberStatus.removed.name,
      'removedAt': FieldValue.serverTimestamp(),
      'removedBy': _auth.uid,
    });
    return batch.commit();
  }

  // ---- 차단 목록 ----
  Stream<List<BlockedUser>> blockedUsers(String churchId) => _paths
      .blocked(churchId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(BlockedUser.fromDoc).where((b) => !b.revoked).toList(),
      );

  /// 등록된 교인 · 입장을 요청한 교인을 차단한다: 목록에 올리고 교회에서 내보낸다 (당사자에게 알림).
  Future<void> blockMember(String churchId, String churchName, Member m) =>
      _removeAndNotify(
        churchId,
        m.id,
        '$churchName 교회에서 차단되었어요',
        '이 교회에는 더 이상 입장할 수 없어요.',
        block: _blockData(m.loginId, m.name),
      );

  /// 아이디를 직접 입력해 차단한다. 이미 교인이면 내보내고 알린다.
  Future<void> blockByLoginId(
    String churchId,
    String churchName,
    String input,
  ) async {
    final id = input.trim().toLowerCase();
    if (id.isEmpty) throw const AppException('차단할 아이디를 입력해 주세요.');
    final snap = await _paths.db.collection('loginIds').doc(id).get();
    final uid = snap.data()?['uid'] as String?;
    if (!snap.exists || uid == null) {
      throw const AppException('그런 아이디의 회원이 없어요.');
    }
    if (uid == _auth.uid) throw const AppException('본인은 차단할 수 없어요.');
    final already = await _paths.blocked(churchId).doc(uid).get();
    if (already.exists && already.data()?['revoked'] != true) {
      throw const AppException('이미 차단된 아이디예요.');
    }
    final member = await _paths.members(churchId).doc(uid).get();
    final name = member.data()?['name'] as String? ?? '';
    if (member.exists &&
        member.data()?['status'] != MemberStatus.removed.name) {
      await _removeAndNotify(
        churchId,
        uid,
        '$churchName 교회에서 차단되었어요',
        '이 교회에는 더 이상 입장할 수 없어요.',
        block: _blockData(id, name),
      );
    } else {
      await _paths.blocked(churchId).doc(uid).set(_blockData(id, name));
    }
  }

  /// 차단을 푼 것으로 표시한다 (기록은 남는다).
  Future<void> unblock(String churchId, String uid) =>
      _paths.blocked(churchId).doc(uid).update({
        'revoked': true,
        'revokedAt': FieldValue.serverTimestamp(),
        'revokedBy': _auth.uid,
      });

  Map<String, dynamic> _blockData(String loginId, String name) => {
    'loginId': loginId,
    'name': name,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Future<void> setStatus(String churchId, String userId, MemberStatus status) =>
      _paths.members(churchId).doc(userId).update({'status': status.name});

  Future<void> setRole(String churchId, String userId, Role role) =>
      _paths.members(churchId).doc(userId).update({'role': role.name});

  /// 인원 상세 관리: 넘긴 항목만 저장한다. 이름·전화번호는 한 번에 쓰고,
  /// 역할·상태는 규칙이 따로 허용하므로 따로 쓴다.
  Future<void> saveMember(
    Member m, {
    String? name,
    String? phone,
    String? address,
    String? birthDate,
    List<String>? affiliationIds,
    Role? role,
    MemberStatus? status,
  }) async {
    final info = <String, Object>{};
    if (name != null) {
      final n = name.trim();
      if (n.isEmpty || n.length > 30) {
        throw const AppException('이름은 1~30자로 입력해 주세요.');
      }
      info['name'] = n;
    }
    if (phone != null) {
      final p = phone.trim();
      if (p.isNotEmpty && (p.length < 8 || p.length > 20)) {
        throw const AppException('전화번호를 8~20자로 입력해 주세요.');
      }
      info['phone'] = p;
    }
    if (address != null) {
      if (address.trim().length > 200) {
        throw const AppException('주소는 200자까지 쓸 수 있어요.');
      }
      info['address'] = address.trim();
    }
    if (birthDate != null) {
      final b = birthDate.trim();
      if (b.isNotEmpty && DateTime.tryParse(b) == null) {
        throw const AppException('생년월일 형식이 올바르지 않아요.');
      }
      info['birthDate'] = b;
    }
    if (affiliationIds != null) info['affiliationIds'] = affiliationIds;
    final doc = _paths.members(m.churchId).doc(m.id);
    if (info.isNotEmpty) await doc.update(info);
    if (role != null) {
      await doc.update({'role': role.name});
      // 교회 운영자가 되면 모든 소속에 자동으로 속한다.
      if (role == Role.admin) {
        await admin_affs.syncAdminAffiliations(_paths, m.churchId);
      }
    }
    if (status != null) await doc.update({'status': status.name});
  }

  /// 교회 운영자가 모든 소속에 속해 있게 맞춘다 (이미 맞으면 아무것도 쓰지 않는다).
  Future<void> syncAdminAffiliations(String churchId) =>
      admin_affs.syncAdminAffiliations(_paths, churchId);

  /// 교역자가 교인을 소속에 넣는다 (이미 있으면 그대로).
  Future<void> addToAffiliation(String churchId, String userId, String affId) =>
      _paths.members(churchId).doc(userId).update({
        'affiliationIds': FieldValue.arrayUnion([affId]),
      });

  /// 교역자가 교인을 소속에서 뺀다.
  Future<void> removeFromAffiliation(
    String churchId,
    String userId,
    String affId,
  ) => _paths.members(churchId).doc(userId).update({
    'affiliationIds': FieldValue.arrayRemove([affId]),
  });
}
