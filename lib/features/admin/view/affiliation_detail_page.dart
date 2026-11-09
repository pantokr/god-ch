import '../../../core/widgets/app_loader.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../data/models/permission.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../../../core/widgets/sort_pad.dart';
import '../view_model/affiliation_manage_view_model.dart';
import '../view_model/member_admin_view_model.dart' show MemberSort;
import '../../../core/widgets/member_mark.dart';
import 'member_info_page.dart';
import '../../../core/widgets/app_inputs.dart';

/// 한 소속의 인원 관리 (주소 `/churches/{교회}/affiliations/{소속}`). 목록으로 돌아가는 버튼이 있다.
class AffiliationDetailPage extends StatelessWidget {
  const AffiliationDetailPage({
    super.key,
    required this.me,
    required this.affiliationId,
  });

  final Member me;
  final String affiliationId;

  @override
  Widget build(BuildContext context) =>
      AffiliationDetailBody(me: me, affiliationId: affiliationId);
}

/// 소속 상세의 본문. 뒤로가기는 바깥 화면(상단 바)의 버튼 하나만 쓴다.
class AffiliationDetailBody extends StatefulWidget {
  const AffiliationDetailBody({
    super.key,
    required this.me,
    required this.affiliationId,
  });

  final Member me;
  final String affiliationId;

  @override
  State<AffiliationDetailBody> createState() => _AffiliationDetailBodyState();
}

class _AffiliationDetailBodyState extends State<AffiliationDetailBody> {
  /// 보고 있는 소속.
  String get affiliationId => widget.affiliationId;

  Member get me => widget.me;

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
      builder: (context, vm) => StreamBuilder<List<Affiliation>>(
        stream: vm.affiliations,
        builder: (context, affs) {
          if (!affs.hasData) {
            return const Center(child: AppLoader());
          }
          // 기본 소속 "미배정"은 목록에 없다: 인원을 보기만 하고 고칠 수 없다.
          final readOnly = affiliationId == Affiliation.unassigned.id;
          final affiliation = readOnly
              ? Affiliation.unassigned
              : affs.data!.where((d) => d.id == affiliationId).firstOrNull;
          if (affiliation == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyHint('없는 소속예요.'),
            );
          }
          return StreamBuilder<List<Member>>(
            stream: vm.members,
            builder: (context, members) {
              final all = members.data ?? const <Member>[];
              final everyone = vm.inAffiliation(all, affiliationId);
              final people = vm.shownIn(all, affiliationId);
              return SingleChildScrollView(
                child: PageFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이 소속의 모든 관리가 여기에 있다: 인원 추가 · 이름 변경 · 삭제 (미배정은 보기만).
                      if (!readOnly)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: textGutter(context),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: vm.busy
                                    ? null
                                    : () => _add(context, vm, all),
                                icon: const Icon(AppIcons.userPlus, size: 18),
                                label: const Text('인원 추가'),
                              ),
                              // 이름 변경은 교회 관리자만 한다.
                              if (me.isAdmin)
                                OutlinedButton.icon(
                                  onPressed: vm.busy
                                      ? null
                                      : () => _rename(context, vm, affiliation),
                                  icon: const Icon(
                                    AppIcons.pencilSimple,
                                    size: 18,
                                  ),
                                  label: const Text('이름 변경'),
                                ),
                              // 소속 삭제 권한이 있는 사람만 삭제한다.
                              if (me.can(Permission.affiliationEdit))
                                OutlinedButton.icon(
                                  style: TrashIcon.textStyle(context),
                                  onPressed: vm.busy
                                      ? null
                                      : () => _delete(context, vm, affiliation),
                                  icon: const TrashIcon(),
                                  label: const Text('삭제'),
                                ),
                            ],
                          ),
                        ),
                      if (!readOnly) const SizedBox(height: 16),
                      if (vm.error != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            textGutter(context),
                            0,
                            textGutter(context),
                            12,
                          ),
                          child: Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      // 검색 · 정렬은 회원 관리와 같다: 이름순 · ID순 · 등록순 · 직급순.
                      AppSearchField(
                        inset: true,
                        hint: '이름, 아이디, 전화번호 검색',
                        onChanged: vm.setQuery,
                      ),
                      const SizedBox(height: 12),
                      // 제목(소속 이름과 인원) · 정렬 · 목록이 한 박스 안에 있다 (회원 관리와 같다).
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SortStrip(
                              inBox: true,
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    affiliation.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${everyone.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                              options: [
                                for (final s in MemberSort.values)
                                  PadOption(
                                    s.label,
                                    selected: vm.sort == s,
                                    onTap: () => vm.setSort(s),
                                  ),
                              ],
                            ),
                            const Divider(height: 1),
                            if (people.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(40),
                                child: Center(
                                  child: Text(
                                    everyone.isEmpty
                                        ? '이 소속에 속한 인원이 없어요.'
                                        : '해당하는 인원이 없어요.',
                                    style: TextStyle(
                                      color: context.palette.muted,
                                    ),
                                  ),
                                ),
                              )
                            else
                              for (var i = 0; i < people.length; i++) ...[
                                if (i > 0) const Divider(),
                                _PersonRow(
                                  member: people[i],
                                  affiliationName: affiliation.name,
                                  isSelf: people[i].id == me.id,
                                  busy: vm.busy,
                                  readOnly: readOnly,
                                  onRemove: () async {
                                    // 소속에서 제외하기 전에 한 번 더 묻는다.
                                    final ok = await confirmChange(
                                      context,
                                      title:
                                          '${people[i].name}님을 ${affiliation.name}에서 제외할까요?',
                                      confirmLabel: '제외',
                                      danger: true,
                                    );
                                    if (ok) {
                                      await vm.remove(affiliationId, people[i]);
                                    }
                                  },
                                ),
                              ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 이름 변경: 이름 입력 창을 띄우고 바뀐 이름을 저장한다.
  Future<void> _rename(
    BuildContext context,
    AffiliationManageViewModel vm,
    Affiliation affiliation,
  ) async {
    final name = await showAppDialog<String>(
      context,
      maxWidth: 420,
      child: _RenameForm(initial: affiliation.name),
    );
    if (name == null || name.trim().isEmpty) return;
    await vm.rename(affiliation.id, name);
  }

  /// 삭제: 확인 팝업 뒤에 소속을 지우고(인원의 기록은 남는다) 목록으로 돌아간다.
  Future<void> _delete(
    BuildContext context,
    AffiliationManageViewModel vm,
    Affiliation affiliation,
  ) async {
    final navigator = Navigator.of(context);
    final ok = await confirmChange(
      context,
      title: '"${affiliation.name}" 소속을 삭제할까요?',
      body: '목록에서 사라져요. 이 소속에 있던 인원은 그대로예요.',
      confirmLabel: '삭제',
      danger: true,
    );
    if (!ok) return;
    if (await vm.delete(affiliation.id)) navigator.maybePop();
  }

  Future<void> _add(
    BuildContext context,
    AffiliationManageViewModel vm,
    List<Member> all,
  ) async {
    final picked = await showAppDialog<List<Member>>(
      context,
      maxWidth: 480,
      child: _AddPeopleForm(candidates: vm.candidates(all, affiliationId)),
    );
    if (picked == null || picked.isEmpty) return;
    await vm.add(affiliationId, picked);
  }
}

/// 소속 이름 입력 창 내용. 저장하면 입력한 이름을 돌려준다.
class _RenameForm extends StatefulWidget {
  const _RenameForm({required this.initial});

  final String initial;

  @override
  State<_RenameForm> createState() => _RenameFormState();
}

class _RenameFormState extends State<_RenameForm> {
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
        Text('소속 이름 변경', style: Theme.of(context).textTheme.titleLarge),
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

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.member,
    required this.busy,
    required this.onRemove,
    required this.affiliationName,
    this.isSelf = false,
    this.readOnly = false,
  });

  final Member member;

  /// 이 소속의 이름 (상세 페이지의 소속 칩).
  final String affiliationName;
  final bool isSelf;
  final bool busy;
  final bool readOnly;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    // 다른 관리 목록과 같은 줄 모양: 이름 · 소속 교회 · 전화번호 · [제외]. 줄을 누르면 상세가 열린다.
    return ManageListRow(
      onTap: () => _open(context),
      leading: ManageListRow.avatar(
        context,
        member.name,
        imageUrl: member.photoUrl,
      ),
      title: member.loginId.isEmpty
          ? member.name
          : '${member.name}  (${member.loginId})',
      // 교회 관리자는 이름 앞에 왕관, 교역자는 방패로 표시한다 (회원 관리 · 우리 소속과 같다).
      titleMark: MemberMark(role: member.role),
      badge: isSelf ? '본인' : null,
      trailing: [
        TextButton(onPressed: () => _open(context), child: const Text('관리')),
      ],
    );
  }

  /// 상세 페이지로 이동한다 (회원 관리와 같은 페이지). 소속에서 제외하는 버튼이 관리 카드에 있다.
  void _open(BuildContext context) => showMemberInfoPage(
    context,
    member: member,
    positionName: memberPositionLabel(member),
    affiliationNames: [affiliationName],
    // 교회 운영자는 모든 소속에 자동으로 속하므로 뺄 수 없다.
    footer: readOnly || member.role == Role.admin
        ? null
        : SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: busy
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      await onRemove();
                      navigator.maybePop();
                    },
              icon: const Icon(AppIcons.userMinus, size: 18),
              label: const Text('소속에서 제외'),
            ),
          ),
  );
}

/// 소속에 넣을 인원을 고르는 대화상자. 이름·전화번호로 찾고 여러 명을 한꺼번에 고른다.
class _AddPeopleForm extends StatefulWidget {
  const _AddPeopleForm({required this.candidates});

  final List<Member> candidates;

  @override
  State<_AddPeopleForm> createState() => _AddPeopleFormState();
}

class _AddPeopleFormState extends State<_AddPeopleForm> {
  String _query = '';
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final shown = widget.candidates
        .where(
          (m) =>
              q.isEmpty ||
              m.name.toLowerCase().contains(q) ||
              m.phone.replaceAll('-', '').contains(q.replaceAll('-', '')),
        )
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('인원 추가', style: Theme.of(context).textTheme.titleLarge),
        AppField.spacer,
        AppSearchField(
          autofocus: true,
          hint: '이름이나 전화번호로 찾기',
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              widget.candidates.isEmpty ? '추가할 수 있는 인원이 없어요.' : '찾는 인원이 없어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final m in shown)
                  CheckboxListTile(
                    dense: true,
                    value: _picked.contains(m.id),
                    onChanged: (on) => setState(
                      () =>
                          on == true ? _picked.add(m.id) : _picked.remove(m.id),
                    ),
                    title: Text(m.name),
                    subtitle: m.phone.isEmpty ? null : Text(m.phone),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _picked.isEmpty
                  ? null
                  : () => Navigator.pop(context, [
                      for (final m in widget.candidates)
                        if (_picked.contains(m.id)) m,
                    ]),
              child: Text(_picked.isEmpty ? '추가' : '${_picked.length}명 추가'),
            ),
          ],
        ),
      ],
    );
  }
}
