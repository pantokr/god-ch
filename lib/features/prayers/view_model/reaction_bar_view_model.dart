import '../../../core/mvvm/view_model.dart';
import '../../../data/models/prayer_settings.dart';
import '../../../data/models/reaction.dart';
import '../data/prayer_repository.dart';

/// 한 기도제목의 이모티콘 응원. 이모티콘별 개수와 내 선택만 다룬다.
class ReactionBarViewModel extends ViewModel {
  ReactionBarViewModel(this._prayers, this._churchId, this._prayerId)
    : summary = _prayers.reactions(_churchId, _prayerId),
      settings = _prayers.settings(_churchId);

  final PrayerRepository _prayers;
  final String _churchId;
  final String _prayerId;
  final Stream<ReactionSummary> summary;

  /// 교회가 정한 응원 설정 (쓸 수 있는 이모티콘 · 개수 표시).
  final Stream<PrayerSettings> settings;

  Future<void> toggle(String type, {required bool currentlyOn}) => run(
    () => _prayers.toggleReaction(_churchId, _prayerId, type, currentlyOn),
  );
}
