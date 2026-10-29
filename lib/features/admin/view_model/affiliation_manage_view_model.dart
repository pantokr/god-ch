import '../../../core/app_exception.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../church/data/affiliation_repository.dart';
import '../../members/data/member_repository.dart';

/// 소속 관리: 소속 목록(만들기 · 이름 변경)과 소속별 인원(추가 · 빼기).
/// 목록 화면과 소속 상세 화면이 함께 쓴다. 스트림은 한 번만 만든다.
class AffiliationManageViewModel extends ViewModel {
  AffiliationManageViewModel(this._affiliations, this._members, this.churchId)
    : affiliations = _affiliations.affiliations(churchId),
      members = _members.members(churchId),
      features = _affiliations.features(churchId) {
    // 교회 운영자가 모든 소속에 속해 있게 맞춘다 (예전 데이터 포함, 이미 맞으면 쓰지 않는다).
    _members.syncAdminAffiliations(churchId).catchError((_) {});
  }

  final AffiliationRepository _affiliations;
  final MemberRepository _members;
  final String churchId;
  final Stream<List<Affiliation>> affiliations;
  final Stream<List<Member>> members;

  /// 소속별로 기도 · 말씀 탭을 쓸 수 있는지.
  final Stream<ChurchFeatures> features;

  /// 이 소속에 속한 인원. 이름 순.
  List<Member> inAffiliation(List<Member> all, String affiliationId) =>
      all.where((m) => m.affiliationIds.contains(affiliationId)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  /// 이 소속에 넣을 수 있는 인원: 승인된 교인 중 아직 속하지 않은 사람.
  List<Member> candidates(List<Member> all, String affiliationId) =>
      all
          .where(
            (m) => m.isApproved && !m.affiliationIds.contains(affiliationId),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  /// [affiliation] 소속의 [feature](기도 · 말씀)를 켜거나 끈다.
  Future<bool> setFeature(
    ChurchFeatures current,
    List<Affiliation> all,
    Affiliation affiliation,
    PageFeature feature,
    bool on,
  ) => run(
    () => _affiliations.setFeatures(
      churchId,
      current.toggled(feature, affiliation.id, on, [for (final d in all) d.id]),
    ),
  );

  Future<bool> create(String name) =>
      run(() => _affiliations.create(churchId, name));

  Future<bool> rename(String id, String name) =>
      run(() => _affiliations.rename(churchId, id, name));

  Future<bool> add(String affiliationId, Iterable<Member> people) =>
      run(() async {
        for (final m in people) {
          await _members.addToAffiliation(churchId, m.id, affiliationId);
        }
      });

  /// 교회 운영자는 모든 소속에 자동으로 속하므로 소속에서 뺄 수 없다.
  Future<bool> remove(String affiliationId, Member m) => run(() {
    if (m.role == Role.admin) {
      throw const AppException('교회 운영자는 모든 소속에 자동으로 속해요.');
    }
    return _members.removeFromAffiliation(churchId, m.id, affiliationId);
  });
}
