import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/address/address_search.dart';
import '../../../core/widgets/required_label.dart';

/// 주소(도로명 주소 검색)와 생년월일(날짜 선택) 입력란. 바깥 [Form] 안에 놓아야 한다.
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

  Future<void> _searchAddress() async {
    setState(() => _searchError = null);
    try {
      final result = await searchRoadAddress();
      if (result == null || !mounted) return;
      setState(() => widget.address.text = result.roadAddress);
      _addressField.currentState?.didChange(widget.address.text);
      _addressField.currentState?.validate();
    } catch (e) {
      if (mounted) setState(() => _searchError = '$e');
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(widget.birthDate.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '생년월일',
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(
      () => widget.birthDate.text =
          '${picked.year}-${two(picked.month)}-${two(picked.day)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showAddress)
          FormField<String>(
            key: _addressField,
            validator: (_) =>
                widget.requireAddress && widget.address.text.trim().isEmpty
                ? '주소를 입력해 주세요'
                : null,
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.address,
                          enabled: widget.enabled,
                          readOnly: isAddressSearchSupported,
                          onTap:
                              isAddressSearchSupported &&
                                  widget.address.text.isEmpty
                              ? _searchAddress
                              : null,
                          onChanged: (_) =>
                              state.didChange(widget.address.text),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(200),
                          ],
                          decoration: InputDecoration(
                            label: RequiredLabel(
                              '주소',
                              required: widget.requireAddress,
                            ),
                            hintText: isAddressSearchSupported
                                ? '주소 검색을 눌러 도로명 주소를 선택하세요'
                                : '도로명 주소를 입력하세요',
                          ),
                        ),
                      ),
                      if (isAddressSearchSupported && widget.enabled) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _searchAddress,
                          icon: const Icon(AppIcons.magnifyingGlass, size: 18),
                          label: const Text('주소 검색'),
                        ),
                      ],
                    ],
                  ),
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
        if (widget.showAddress && widget.showBirthDate)
          const SizedBox(height: 12),
        if (widget.showBirthDate)
          TextFormField(
            controller: widget.birthDate,
            enabled: widget.enabled,
            readOnly: true,
            onTap: _pickBirthDate,
            decoration: InputDecoration(
              label: RequiredLabel('생년월일', required: widget.requireBirthDate),
              hintText: '눌러서 날짜를 고르세요',
              suffixIcon: widget.birthDate.text.isEmpty || !widget.enabled
                  ? const Icon(AppIcons.calendar, size: 18)
                  : IconButton(
                      tooltip: '지우기',
                      icon: const Icon(AppIcons.x, size: 18),
                      onPressed: () => setState(() => widget.birthDate.clear()),
                    ),
            ),
            validator: (v) =>
                widget.requireBirthDate && (v ?? '').trim().isEmpty
                ? '생년월일을 입력해 주세요'
                : null,
          ),
      ],
    );
  }
}
