import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer_settings.dart';
import '../data/prayer_repository.dart';
import 'prayer_settings_panel.dart';

/// 중보기도 설정 (교회 운영자): 중보기도를 누가 쓰고 어떻게 운영할지 정한다.
class PrayerSettingsPage extends StatelessWidget {
  const PrayerSettingsPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<_SettingsViewModel>(
      key: ValueKey('prayer-settings/${me.churchId}'),
      create: (context) =>
          _SettingsViewModel(AppScope.read(context).prayers, me.churchId),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(title: '중보기도 설정'),
              FutureBuilder<PrayerSettings>(
                future: vm.loaded,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('불러오지 못했습니다\n${snap.error}');
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
                      PrayerSettingsPanel(
                        settings: current,
                        onChanged: vm.edit,
                      ),
                      const SizedBox(height: 16),
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
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('저장했어요.')),
                                    );
                                  }
                                },
                          child: const Text('저장'),
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

class _SettingsViewModel extends ViewModel {
  _SettingsViewModel(this._repo, this._churchId)
    : loaded = _repo.loadSettings(_churchId);

  final PrayerRepository _repo;
  final String _churchId;
  Future<PrayerSettings> loaded;

  /// 고쳤지만 아직 저장하지 않은 설정. 고친 것이 없으면 null.
  PrayerSettings? edited;

  void edit(PrayerSettings v) {
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
