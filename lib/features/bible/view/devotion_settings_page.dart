import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/panel_surface.dart';
import '../../../data/models/devotion_settings.dart';
import '../../../data/models/member.dart';
import '../../home/data/content_repository.dart';

/// 말씀묵상 설정 (교회 운영자): 좋아요 · 댓글 · 조회수 · 글쓴이를 어떻게 운영할지 정한다.
/// 중보기도 설정과 같은 틀이다: 묶음마다 체크 항목이 있고, 맨 아래 저장 버튼으로 한 번에 저장한다.
class DevotionSettingsPage extends StatelessWidget {
  const DevotionSettingsPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<_SettingsViewModel>(
      key: ValueKey('devotion-settings/${me.churchId}'),
      create: (context) =>
          _SettingsViewModel(AppScope.read(context).contents, me.churchId),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(title: '말씀묵상 설정'),
              FutureBuilder<DevotionSettings>(
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
                      _Panel(settings: current, onChanged: vm.edit),
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

/// 운영 원칙: 반응 · 댓글 · 공개 세 묶음.
class _Panel extends StatelessWidget {
  const _Panel({required this.settings, required this.onChanged});

  final DevotionSettings settings;
  final ValueChanged<DevotionSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return PanelSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('운영 원칙', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _Group('반응'),
          _Check(
            label: '좋아요 허용',
            value: s.allowLikes,
            onChanged: (v) => onChanged(s.copyWith(allowLikes: v)),
          ),
          const _Group('댓글'),
          _Check(
            label: '댓글 허용',
            value: s.allowReflections,
            onChanged: (v) => onChanged(s.copyWith(allowReflections: v)),
          ),
          _Check(
            label: '댓글 공개 (끄면 본인과 교역자만)',
            value: s.reflectionsPublic,
            onChanged: (v) => onChanged(s.copyWith(reflectionsPublic: v)),
          ),
          const _Group('공개'),
          _Check(
            label: '조회수 공개',
            value: s.showViews,
            onChanged: (v) => onChanged(s.copyWith(showViews: v)),
          ),
          _Check(
            label: '글쓴이 공개',
            value: s.showAuthor,
            onChanged: (v) => onChanged(s.copyWith(showAuthor: v)),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      title,
      style: TextStyle(
        color: context.palette.muted,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Check extends StatelessWidget {
  const _Check({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: value,
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(label),
    onChanged: (v) => onChanged(v ?? false),
  );
}

class _SettingsViewModel extends ViewModel {
  _SettingsViewModel(this._repo, this._churchId)
    : loaded = _repo.loadSettings(_churchId);

  final ContentRepository _repo;
  final String _churchId;
  Future<DevotionSettings> loaded;

  /// 고쳤지만 아직 저장하지 않은 설정. 고친 것이 없으면 null.
  DevotionSettings? edited;

  void edit(DevotionSettings v) {
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
