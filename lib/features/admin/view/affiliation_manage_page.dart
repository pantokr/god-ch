import '../../../core/widgets/app_loader.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/labeled_field.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../data/models/permission.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/affiliation_manage_view_model.dart';
import 'affiliation_detail_page.dart';
import '../../../core/theme.dart';

/// 소속 관리: 소속 목록(만들기 · 이름 변경)과 소속별 인원 수. 소속을 누르면 그 소속의 인원을 관리한다.
/// [onOpen]이 없으면(앱 운영자 패널) 전체 화면으로 소속 상세를 연다.
class AffiliationManagePage extends StatelessWidget {
  const AffiliationManagePage({super.key, required this.me, this.onOpen});

  final Member me;
  final void Function(Affiliation affiliation)? onOpen;

  /// 소속 카드를 누르면 바로 그 소속의 인원 화면으로 간다.
  void _open(BuildContext context, Affiliation d) {
    final open = onOpen;
    if (open != null) return open(d);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          // 상단 바 없이 뒤로가기 버튼만 내용 위에 둔다.
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: '돌아가기',
                    icon: const Icon(AppIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: AffiliationDetailBody(me: me, affiliationId: d.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AffiliationManageViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return AffiliationManageViewModel(
          scope.affiliations,
          scope.members,
          me.churchId,
        );
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          // 이 화면은 내용 전체가 좌우 여백 안에 놓인다.
          inset: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목 옆이 아니라 다음 줄에 둔다.
              // 소속을 만들고 고치는 것은 앱을 고치는 일이라 교회 관리자만 한다 (교역자는 조회와 인원 배치).
              if (me.can(Permission.affiliationEdit)) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _edit(context, vm),
                    icon: const Icon(AppIcons.plus, size: 18),
                    label: const Text('소속 만들기'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              StreamBuilder<List<Affiliation>>(
                stream: vm.affiliations,
                builder: (context, affs) {
                  if (affs.hasError) {
                    return Text('불러오지 못했습니다\n${affs.error}');
                  }
                  final items = affs.data;
                  if (items == null) {
                    return const Center(child: AppLoader());
                  }
                  return StreamBuilder<List<Member>>(
                    stream: vm.members,
                    builder: (context, members) {
                      final all = members.data ?? const <Member>[];
                      // 소속마다 카드 한 장: 격자로 늘어놓는다 (좁은 화면에서도 두 열).
                      return ColumnWrap(
                        wide: 2,
                        narrow: 2,
                        children: [
                          // 기본 소속 "미배정": 소속 없이 입장한 교인이 있다. 이름 변경 · 삭제가 없다.
                          _UnassignedCard(
                            count: vm
                                .inAffiliation(all, Affiliation.unassigned.id)
                                .length,
                            onEdit: () =>
                                _open(context, Affiliation.unassigned),
                          ),
                          for (final d in items)
                            _AffiliationCard(
                              affiliation: d,
                              count: vm.inAffiliation(all, d.id).length,
                              onEdit: () => _open(context, d),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              if (vm.error != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    textGutter(context),
                    12,
                    textGutter(context),
                    0,
                  ),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    AffiliationManageViewModel vm, {
    Affiliation? affiliation,
  }) async {
    final name = await showAppDialog<String>(
      context,
      maxWidth: 420,
      child: _AffiliationNameForm(initial: affiliation?.name),
    );
    if (name == null || name.trim().isEmpty) return;
    if (affiliation == null) {
      await vm.create(name);
    } else {
      await vm.rename(affiliation.id, name);
    }
  }
}

/// 소속 카드: 아이콘, 소속 이름, 인원 수. 누르면 그 소속의 인원 관리가 열리고, 연필로 이름을 바꾼다.
class _AffiliationCard extends StatelessWidget {
  const _AffiliationCard({
    required this.affiliation,
    required this.count,
    required this.onEdit,
  });

  final Affiliation affiliation;
  final int count;

  /// 오른쪽 위 수정 버튼: 그 소속의 관리 화면으로 간다. 카드의 나머지 부분은 눌러도 아무 일도 없다.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: radius,
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: AppShadow.soft(context),
      ),
      child: SizedBox(
        // 글씨가 커져도 넘치지 않게 글 영역만큼 높이가 따라 커진다.
        height: _cardHeight(context),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppDepth.brand(context),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(
                      AppIcons.usersThree,
                      size: 22,
                      color: palette.onBrand,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    affiliation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count명',
                    style: TextStyle(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: '수정',
                icon: const Icon(AppIcons.pencilSimple, size: 20),
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 기본 소속 "미배정" 카드: 입장할 때 소속을 고르지 않은 교인의 수. 지울 수 없고 눌러도 열리지 않는다.
class _UnassignedCard extends StatelessWidget {
  const _UnassignedCard({required this.count, required this.onEdit});

  final int count;

  /// 수정 버튼: 이름 변경 · 삭제는 없고, 속한 사람을 볼 수만 있는 화면이 열린다.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      // 글씨가 커져도 넘치지 않게 글 영역만큼 높이가 따라 커진다.
      height: _cardHeight(context),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: AppShadow.soft(context),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 다른 소속 카드와 같은 모양: 프로필 아이콘 오른쪽에 자물쇠(기본 소속 표시)만 더한다.
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.muted.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Icon(
                        AppIcons.usersThree,
                        size: 22,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(AppIcons.lock, size: 16, color: palette.muted),
                  ],
                ),
                const Spacer(),
                Text(
                  Affiliation.unassignedName,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count명',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: '수정',
              icon: const Icon(AppIcons.pencilSimple, size: 20),
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

/// 소속 이름 입력 대화상자 내용. 저장하면 입력한 이름을 돌려준다.
class _AffiliationNameForm extends StatefulWidget {
  const _AffiliationNameForm({this.initial});

  final String? initial;

  @override
  State<_AffiliationNameForm> createState() => _AffiliationNameFormState();
}

class _AffiliationNameFormState extends State<_AffiliationNameForm> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initial == null ? '소속 만들기' : '소속 이름 변경',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        AppField.spacer,
        LabeledField(
          label: '소속 이름',
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              child: const Text('저장'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 소속 카드 높이: 기본 156에, 글씨 확대 배율만큼 글 영역(약 60)을 더한다.
double _cardHeight(BuildContext context) =>
    156 + 60 * (MediaQuery.textScalerOf(context).scale(1) - 1);
