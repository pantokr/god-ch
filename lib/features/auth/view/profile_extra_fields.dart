import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/address_input.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/labeled_field.dart';

/// 생년월일(날짜 선택)과 주소(도로명 주소 검색) 입력란 (이 차례로 놓인다). 바깥 [Form] 안에 놓아야 한다.
/// 기본은 선택 입력이고, [requireAddress]·[requireBirthDate]를 켜면 비워 둘 수 없다.
class ProfileExtraFields extends StatefulWidget {
  const ProfileExtraFields({
    super.key,
    required this.address,
    required this.birthDate,
    this.showAddress = true,
    this.showBirthDate = true,
    this.requireAddress = false,
    this.requireBirthDate = false,
    this.enabled = true,
  });

  final TextEditingController address;

  /// YYYY-MM-DD 형식으로 담긴다. 비어 있으면 입력하지 않은 것이다.
  final TextEditingController birthDate;
  final bool showAddress;
  final bool showBirthDate;
  final bool requireAddress;
  final bool requireBirthDate;
  final bool enabled;

  @override
  State<ProfileExtraFields> createState() => _ProfileExtraFieldsState();
}

class _ProfileExtraFieldsState extends State<ProfileExtraFields> {
  final _addressField = GlobalKey<FormFieldState<String>>();
  String? _searchError;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(widget.birthDate.text);
    final picked = await showAppDatePicker(
      context,
      initialDate: current ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      title: '생년월일',
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(
      () => widget.birthDate.text =
          '${picked.year}-${two(picked.month)}-${two(picked.day)}',
    );
  }

  /// 이름표는 왼쪽, 입력칸은 오른쪽에 둔다.
  Widget _above(String label, bool required, Widget field) =>
      LabeledField(label: label, required: required, child: field);

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showBirthDate)
          _above(
            '생년월일',
            widget.requireBirthDate,
            TextFormField(
              controller: widget.birthDate,
              enabled: widget.enabled,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: InputDecoration(
                hintText: widget.enabled ? '눌러서 날짜를 고르세요' : '미제공',
                suffixIcon: widget.birthDate.text.isEmpty || !widget.enabled
                    ? const Icon(AppIcons.calendar, size: 18)
                    : IconButton(
                        tooltip: '지우기',
                        icon: const Icon(AppIcons.x, size: 18),
                        onPressed: () =>
                            setState(() => widget.birthDate.clear()),
                      ),
              ),
              validator: (v) =>
                  widget.requireBirthDate && (v ?? '').trim().isEmpty
                  ? '생년월일을 입력해 주세요'
                  : null,
            ),
          ),
        if (widget.showAddress && widget.showBirthDate)
          const SizedBox(height: 12),
        if (widget.showAddress)
          FormField<String>(
            key: _addressField,
            validator: (_) =>
                widget.requireAddress && widget.address.text.trim().isEmpty
                ? '주소를 입력해 주세요'
                : null,
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 기본 주소(검색 아이콘 버튼) + 상세 주소 두 칸.
                AddressInput(
                  controller: widget.address,
                  enabled: widget.enabled,
                  required: widget.requireAddress,
                  onChanged: () => state.didChange(widget.address.text),
                  onSearched: () {
                    setState(() => _searchError = null);
                    state.validate();
                  },
                  onError: (e) => setState(() => _searchError = e),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(color: error, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_searchError!, style: TextStyle(color: error)),
          ),
      ],
    );
  }
}
