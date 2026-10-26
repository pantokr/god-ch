import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/thumbnail_field.dart';
import '../../../data/models/church.dart';
import '../../../data/models/member.dart';
import '../../church/view/church_info_fields.dart';
import '../view_model/church_registry_view_model.dart';
import '../view_model/church_summary_view_model.dart';

/// 교회 정보 탭: 교회의 모든 정보가 입력란에 들어 있고, 맨 아래 저장 버튼으로 한 번에 저장한다.
class ChurchInfoForm extends StatefulWidget {
  const ChurchInfoForm({super.key, required this.church});

  final Church church;

  @override
  State<ChurchInfoForm> createState() => _ChurchInfoFormState();
}

class _ChurchInfoFormState extends State<ChurchInfoForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.church.name);
  late final _phone = TextEditingController(text: widget.church.phone);
  late final _address = TextEditingController(text: widget.church.address);
  late final _thumbnail = TextEditingController(
    text: widget.church.thumbnailUrl,
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _thumbnail.dispose();
    super.dispose();
  }

  Future<void> _save(ChurchRegistryViewModel vm) async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.update(
      widget.church.id,
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
      thumbnailUrl: _thumbnail.text,
    );
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('저장했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final church = widget.church;
    return ViewModelBuilder<ChurchRegistryViewModel>(
      create: (context) =>
          ChurchRegistryViewModel(AppScope.read(context).churchRegistry),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageTitle(
                  title: '교회 정보',
                  subtitle: '교회의 정보를 고치고 아래의 저장을 눌러요.',
                ),
                ThumbnailField(
                  controller: _thumbnail,
                  name: widget.church.name,
                  label: '썸네일 이미지',
                  upload: (fileName, bytes) =>
                      vm.uploadThumbnail(widget.church.id, fileName, bytes),
                ),
                const SizedBox(height: 16),
                ChurchInfoFields(
                  name: _name,
                  phone: _phone,
                  address: _address,
                  autofocus: false,
                ),
                const SizedBox(height: 24),
                _Summary(church: church),
                if (vm.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: vm.busy ? null : () => _save(vm),
                    child: const Text('저장'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 고칠 수 없는 현황: 등록일, 교인 수, 승인 대기, 교회 운영자.
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
              _Row('등록일', fmtDate(church.createdAt)),
              _Row('교인', snap.hasData ? '$approved명' : '-'),
              _Row('승인 대기', snap.hasData ? '$pending명' : '-'),
              _Row(
                '교회 운영자',
                !snap.hasData
                    ? '-'
                    : (owners.isEmpty
                          ? '아직 없어요 (초대 코드로 들어온 교인을 교회 운영자로 지정하세요)'
                          : owners),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: context.palette.muted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
