import '../../../core/mvvm/view_model.dart';
import '../../../data/models/inquiry.dart';
import '../data/inquiry_repository.dart';

/// 문의 보내기와 내가 보낸 문의 목록. 스트림은 만들 때 한 번만 만든다.
class InquiryViewModel extends ViewModel {
  InquiryViewModel(this._repo) : mine = _repo.mine();

  final InquiryRepository _repo;
  final Stream<List<Inquiry>> mine;

  /// 문의를 보낸다. 성공하면 true.
  Future<bool> send(String title, String message) =>
      run(() => _repo.send(title: title, message: message));

  Future<bool> remove(Inquiry inquiry) => run(() => _repo.remove(inquiry.id));
}

/// 앱 운영자 > 문의: 모든 문의를 보고 답변한다.
class InquiryAdminViewModel extends ViewModel {
  InquiryAdminViewModel(this._repo) : all = _repo.all();

  final InquiryRepository _repo;
  final Stream<List<Inquiry>> all;

  /// null이면 전체, true이면 답변 완료, false이면 답변 대기.
  bool? _answered;
  bool? get answered => _answered;

  void setAnswered(bool? v) {
    if (_answered == v) return;
    _answered = v;
    notifyListeners();
  }

  List<Inquiry> apply(List<Inquiry> all) => [
    for (final i in all)
      if (_answered == null || i.answered == _answered) i,
  ];

  Future<bool> reply(Inquiry inquiry, String text) =>
      run(() => _repo.answer(inquiry, text));
}
