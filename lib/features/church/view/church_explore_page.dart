import '../../../core/widgets/app_loader.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../data/models/church.dart';
import '../../../data/models/member.dart';
import '../../../data/models/profile_field.dart';
import '../../auth/view/profile_extra_fields.dart';
import '../../auth/view_model/account_view_model.dart';
import '../../home/view/content_widgets.dart';
import '../../notifications/view/notifications_button.dart';
import '../view_model/church_explore_view_model.dart';
import 'church_request_dialog.dart';
import 'join_church_dialog.dart';

/// 주소 `/explore`: 교회 탐색. 교역자가 공개 탐색에 노출한 교회를 찾아 입장을 요청하고,
/// 교역자가 승인하면 교인이 된다. 비공개 교회는 여기에 나오지 않고 초대 코드로만 들어온다.
class ChurchExplorePage extends StatelessWidget {
  const ChurchExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 교회에 속하지 않았어도 볼 수 있는 오른쪽 계정 띠가 함께 있다.
    return Scaffold(
      body: Row(
        children: [
          const Expanded(child: _ExploreBody()),
          ViewModelBuilder<AccountViewModel>(
            create: (context) => AccountViewModel(AppScope.read(context).auth),
            builder: (context, account) => AccountRail(
              userName: account.userName,
              onProfile: () => context.push(Routes.account),
              onSignOut: account.signOut,
              actions: const [NotificationsButton()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreBody extends StatelessWidget {
  const _ExploreBody();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchExploreViewModel>(
      create: (context) =>
          ChurchExploreViewModel(AppScope.read(context).churches),
      builder: (context, vm) => SubPage(
        title: '교회 탐색',
        fallbackLocation: Routes.churches,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('교회 탐색', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            // 교회에 들어가거나 새로 만드는 다른 길도 여기에 모은다.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showAppDialog<void>(
                    context,
                    child: const JoinChurchDialog(),
                  ),
                  icon: const Icon(AppIcons.key, size: 18),
                  label: const Text('초대 코드로 입장'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showAppDialog<void>(
                    context,
                    child: const ChurchRequestDialog(),
                  ),
                  icon: const Icon(AppIcons.plus, size: 18),
                  label: const Text('교회 생성 요청'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSearchField(hint: '교회 이름 · 주소', onChanged: vm.setQuery),
            const SizedBox(height: 12),
            StreamBuilder<List<Member>>(
              stream: vm.memberships,
              builder: (context, mine) => StreamBuilder<List<Church>>(
                stream: vm.churches,
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
                  // 공개로 노출한 교회가 하나도 없는 것과, 검색에 맞는 교회가 없는 것은 다르다.
                  if (snap.data!.isEmpty) {
                    return const EmptyHint('공개된 교회 없음');
                  }
                  final items = vm.filter(snap.data!);
                  if (items.isEmpty) return const EmptyHint('검색 결과 없음');
                  final status = {
                    for (final m in mine.data ?? const <Member>[])
                      m.churchId: m,
                  };
                  return Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const Divider(),
                          ManageListRow(
                            leading: ManageListRow.avatar(
                              context,
                              items[i].name,
                              imageUrl: items[i].thumbnailUrl,
                            ),
                            title: items[i].name,
                            line1: items[i].region,
                            onTap: () => showAppDialog<void>(
                              context,
                              child: _ChurchDetail(
                                church: items[i],
                                member: status[items[i].id],
                                busy: vm.busy,
                                onRequest: () {
                                  Navigator.pop(context);
                                  _request(context, vm, items[i]);
                                },
                              ),
                            ),
                            trailing: [
                              if (status[items[i].id] != null)
                                _Action(
                                  member: status[items[i].id],
                                  busy: vm.busy,
                                  onRequest: () {},
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (vm.error != null && vm.missing.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _request(
    BuildContext context,
    ChurchExploreViewModel vm,
    Church church,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmChange(
      context,
      title: '${church.name}에 입장 요청',
      body: '교역자가 승인하면 교인이 됩니다.',
      confirmLabel: '요청',
    );
    if (!ok || !context.mounted) return;
    var done = await vm.request(church);
    // 교회가 입장 시 필수로 요청한 정보가 없으면 입력받고 다시 요청한다.
    if (!done && vm.missing.isNotEmpty && context.mounted) {
      final info = await showAppDialog<({String address, String birthDate})>(
        context,
        child: _MissingInfoDialog(church: church, fields: vm.missing),
      );
      if (info == null) return;
      done = await vm.request(
        church,
        address: info.address,
        birthDate: info.birthDate,
      );
    }
    if (done) {
      messenger.showSnackBar(const SnackBar(content: Text('입장을 요청했어요.')));
    }
  }
}

/// 교회를 눌렀을 때 보이는 상세 정보: 사진, 전체 주소, 전화번호, 입장 요청.
class _ChurchDetail extends StatelessWidget {
  const _ChurchDetail({
    required this.church,
    required this.member,
    required this.busy,
    required this.onRequest,
  });

  final Church church;
  final Member? member;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: TextStyle(color: context.palette.muted)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ManageListRow.avatar(
              context,
              church.name,
              imageUrl: church.thumbnailUrl,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                church.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        row('주소', church.address),
        row('전화', church.phone),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            const SizedBox(width: 8),
            if (member == null)
              FilledButton(
                onPressed: busy ? null : onRequest,
                child: const Text('입장 요청'),
              )
            else
              _Action(member: member, busy: busy, onRequest: onRequest),
          ],
        ),
      ],
    );
  }
}

/// 교회 줄 오른쪽: 입장 요청 / 승인 대기 / 입장함 / 거절됨.
class _Action extends StatelessWidget {
  const _Action({
    required this.member,
    required this.busy,
    required this.onRequest,
  });

  final Member? member;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final m = member;
    if (m == null) {
      return FilledButton(
        onPressed: busy ? null : onRequest,
        child: const Text('입장 요청'),
      );
    }
    final label = switch (m.status) {
      MemberStatus.approved => '입장함',
      MemberStatus.pending => '승인 대기',
      _ => '이용 불가',
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(label, style: TextStyle(color: context.palette.muted)),
    );
  }
}

/// 교회가 입장 시 필수로 요청한 정보를 입력받는다.
class _MissingInfoDialog extends StatefulWidget {
  const _MissingInfoDialog({required this.church, required this.fields});

  final Church church;
  final Set<ProfileField> fields;

  @override
  State<_MissingInfoDialog> createState() => _MissingInfoDialogState();
}

class _MissingInfoDialogState extends State<_MissingInfoDialog> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _birthDate = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.church.name} 입장 정보',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppField.spacer,
          ProfileExtraFields(
            address: _address,
            birthDate: _birthDate,
            showAddress: widget.fields.contains(ProfileField.address),
            showBirthDate: widget.fields.contains(ProfileField.birthDate),
            requireAddress: true,
            requireBirthDate: true,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  Navigator.pop(context, (
                    address: _address.text,
                    birthDate: _birthDate.text,
                  ));
                },
                child: const Text('요청'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
