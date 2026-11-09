import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/toast.dart';

import '../../../core/widgets/settings_table.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/meeting_settings.dart';
import '../../../data/models/member.dart';
import '../data/meeting_repository.dart';

/// 모임 일정 설정 (교회 운영자): 좋아요 · 댓글 · 조회수를 어떻게 운영할지 정한다.
/// 말씀묵상 설정과 같은 틀이다: 묶음마다 체크 항목이 있고, 맨 아래 저장 버튼으로 한 번에 저장한다.
class MeetingSettingsPage extends StatelessWidget {
  const MeetingSettingsPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<_SettingsViewModel>(
      key: ValueKey('meeting-settings/${me.churchId}'),
      create: (context) =>
          _SettingsViewModel(AppScope.read(context).meetings, me.churchId),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<MeetingSettings>(
                future: vm.loaded,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text(
                      '불러오지 못했습니다${String.fromCharCode(10)}${snap.error}',
                    );
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    );
                  }
                  final current = vm.edited ?? snap.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Panel(settings: current, onChanged: vm.edit),
                      const SizedBox(height: 16),
                      Gutter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (vm.error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  vm.error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: vm.edited == null || vm.busy
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        if (await vm.save()) {
                                          showToastOn(messenger, '저장했어요.');
                                        }
                                      },
                                child: const Text('저장'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 운영 원칙: 공개 · 댓글 · 반응 세 묶음. 직급 권한과 같은 표 모양이다 (설정 이름 · 켬 · 끔).
class _Panel extends StatelessWidget {
  const _Panel({required this.settings, required this.onChanged});

  final MeetingSettings settings;
  final ValueChanged<MeetingSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsTable(
          title: '공개',
          rows: [
            SettingRow(
              label: '조회수 공개',
              value: s.showViews,
              onChanged: (v) => onChanged(s.copyWith(showViews: v)),
            ),
          ],
        ),
        SettingsTable(
          title: '댓글',
          rows: [
            SettingRow(
              label: '댓글 허용',
              value: s.allowComments,
              onChanged: (v) => onChanged(s.copyWith(allowComments: v)),
            ),
            SettingRow(
              label: '댓글 공개',
              value: s.commentsPublic,
              indent: true,
              onChanged: s.allowComments
                  ? (v) => onChanged(s.copyWith(commentsPublic: v))
                  : null,
            ),
          ],
        ),
        SettingsTable(
          title: '반응',
          rows: [
            SettingRow(
              label: '반응 허용',
              value: s.allowLikes,
              onChanged: (v) => onChanged(s.copyWith(allowLikes: v)),
            ),
            SettingRow(
              label: '좋아요 수 공개',
              value: s.showLikeCount,
              indent: true,
              onChanged: s.allowLikes
                  ? (v) => onChanged(s.copyWith(showLikeCount: v))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsViewModel extends ViewModel {
  _SettingsViewModel(this._repo, this._churchId)
    : loaded = _repo.loadSettings(_churchId);

  final MeetingRepository _repo;
  final String _churchId;
  Future<MeetingSettings> loaded;

  /// 고쳤지만 아직 저장하지 않은 설정. 고친 것이 없으면 null.
  MeetingSettings? edited;

  void edit(MeetingSettings v) {
    edited = v;
    notifyListeners();
  }

  Future<bool> save() async {
    final v = edited;
    if (v == null) return true;
    final ok = await run(() => _repo.saveSettings(_churchId, v));
    if (ok) {
      loaded = Future.value(v);
      edited = null;
      notifyListeners();
    }
    return ok;
  }
}
