import 'package:flutter/material.dart';

import '../../../core/widgets/toast.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../core/widgets/thumbnail_field.dart';
import '../../../data/models/church.dart';
import '../../../data/models/member.dart';
import '../../church/view/church_info_fields.dart';
import '../view_model/church_registry_view_model.dart';
import '../view_model/church_summary_view_model.dart';

/// 교회 관리 페이지로 이동한다 (앱 운영자 > 교회 관리의 교회 줄). 돌아가면 교회 목록이다.
Future<void> showChurchDetailPage(
  BuildContext context, {
  required ChurchRegistryViewModel vm,
  required Church church,
  required VoidCallback onOpen,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  MaterialPageRoute(
    builder: (context) => SubPage(
      title: '',
      barTitle: '교회 관리',
      fallbackLocation: '',
      onBack: () => Navigator.of(context).maybePop(),
      child: ChurchDetailPage(vm: vm, church: church, onOpen: onOpen),
    ),
  ),
);

/// 앱 운영자 > 교회 관리 > 교회 한 곳의 페이지: 현황을 간략히 보고, 정보를 고치고, 조치(노출 · 폐쇄 · 이동)를 한다.
class ChurchDetailPage extends StatefulWidget {
  const ChurchDetailPage({
    super.key,
    required this.vm,
    required this.church,
    required this.onOpen,
  });

  final ChurchRegistryViewModel vm;
  final Church church;

  /// 교회 화면으로 이동한다.
  final VoidCallback onOpen;

  @override
  State<ChurchDetailPage> createState() => _ChurchDetailPageState();
}

class _ChurchDetailPageState extends State<ChurchDetailPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.church.name);
  late final _phone = TextEditingController(text: widget.church.phone);
  late final _address = TextEditingController(text: widget.church.address);
  late final _thumbnail = TextEditingController(
    text: widget.church.thumbnailUrl,
  );
  late final Stream<Church?> _live = widget.vm.church(widget.church.id);

  @override
  void initState() {
    super.initState();
    widget.vm.clearError();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _thumbnail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.vm.update(
      widget.church.id,
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
      thumbnailUrl: _thumbnail.text,
    );
    if (!ok) return;
    navigator.pop();
    showToastOn(messenger, '저장했어요.');
  }

  Future<void> _toggleListed(Church c) async {
    final next = !c.listed;
    final ok = await confirmChange(
      context,
      title: next ? '공개 탐색에 노출할까요?' : '비공개로 바꿀까요?',
      confirmLabel: next ? '노출' : '비공개',
    );
    if (ok) await widget.vm.setListed(c.id, next);
  }

  Future<void> _toggleClosed(Church c) async {
    final next = !c.closed;
    final ok = await confirmChange(
      context,
      title: next ? '${c.name} 교회를 폐쇄할까요?' : '${c.name} 교회의 폐쇄를 풀까요?',
      body: next ? '교인은 더 이상 이 교회를 쓸 수 없어요. 글과 기록은 지워지지 않고 보관돼요.' : '',
      confirmLabel: next ? '폐쇄' : '폐쇄 해제',
      danger: next,
    );
    if (ok) await widget.vm.setClosed(c.id, next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Church?>(
      stream: _live,
      initialData: widget.church,
      builder: (context, snap) {
        final church = snap.data ?? widget.church;
        return ListenableBuilder(
          listenable: widget.vm,
          builder: (context, _) => Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 머리: 썸네일 · 이름 · 상태 표시
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        ThumbnailAvatar(
                          name: church.name,
                          url: church.thumbnailUrl,
                          radius: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                church.name,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: [
                                  _Tag(
                                    church.closed ? '폐쇄' : '운영 중',
                                    warn: church.closed,
                                  ),
                                  _Tag(church.listed ? '공개' : '비공개'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 교회 이동은 작은 버튼으로 둔다.
                        IconButton(
                          tooltip: '교회로 이동',
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpen();
                          },
                          icon: const Icon(AppIcons.arrowRight, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: '현황',
                  child: _Summary(church: church),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: '교회 정보',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ThumbnailField(
                        controller: _thumbnail,
                        name: widget.church.name,
                        label: '썸네일 이미지',
                        upload: (fileName, bytes) => widget.vm.uploadThumbnail(
                          widget.church.id,
                          fileName,
                          bytes,
                        ),
                      ),
                      AppField.spacer,
                      ChurchInfoFields(
                        name: _name,
                        phone: _phone,
                        address: _address,
                        autofocus: false,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: widget.vm.busy ? null : _save,
                          child: const Text('저장'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: '조치',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: widget.vm.busy
                            ? null
                            : () => _toggleListed(church),
                        icon: Icon(
                          church.listed ? AppIcons.prohibit : AppIcons.church,
                          size: 18,
                        ),
                        label: Text(church.listed ? '비공개로 전환' : '공개 탐색에 노출'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: widget.vm.busy
                            ? null
                            : () => _toggleClosed(church),
                        style: church.closed
                            ? null
                            : OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                        icon: Icon(
                          church.closed ? AppIcons.church : AppIcons.warning,
                          size: 18,
                        ),
                        label: Text(church.closed ? '폐쇄 해제' : '교회 폐쇄'),
                      ),
                    ],
                  ),
                ),
                if (widget.vm.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.vm.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 현황: 생성일, 교인 수, 승인 대기, 교회 관리자.
class _Summary extends StatelessWidget {
  const _Summary({required this.church});

  final Church church;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchSummaryViewModel>(
      create: (context) =>
          ChurchSummaryViewModel(AppScope.read(context).members, church.id),
      builder: (context, vm) => StreamBuilder<List<Member>>(
        stream: vm.members,
        builder: (context, snap) {
          final members = snap.data ?? const <Member>[];
          final approved = members.where((m) => m.isApproved).length;
          final pending = members
              .where((m) => m.status == MemberStatus.pending)
              .length;
          final owners = members
              .where((m) => m.isApproved && m.role == Role.admin)
              .map((m) => m.name)
              .join(', ');
          return Column(
            children: [
              _Row('생성일', fmtDate(church.createdAt)),
              _Row('교인', snap.hasData ? '$approved명' : '-'),
              _Row('승인 대기', snap.hasData ? '$pending명' : '-'),
              _Row(
                '교회 관리자',
                !snap.hasData ? '-' : (owners.isEmpty ? '없음' : owners),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: context.palette.muted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// 이름 옆의 작은 상태 표시. [warn]이면 코랄.
class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.warn = false});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = warn ? palette.accent : palette.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 페이지의 한 구역: 카드 위에 제목과 내용.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // 목록 칸(ListTile)이 카드 바탕 위에서 그려지도록 투명한 Material로 감싼다.
            Material(type: MaterialType.transparency, child: child),
          ],
        ),
      ),
    );
  }
}
