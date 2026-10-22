import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/address/address_search.dart';
import '../../../core/formatters/korean_phone.dart';

/// 교회 이름 · 전화번호(형식 자동) · 주소(도로명 주소 검색) 입력란.
/// 교회 생성 요청과 앱 운영자의 교회 직접 등록이 함께 쓴다. 바깥 [Form] 안에 놓아야 한다.
class ChurchInfoFields extends StatefulWidget {
  const ChurchInfoFields({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    this.phoneRequired = true,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController address;

  /// false면 전화번호를 비워 둘 수 있다 (입력했다면 형식은 검사한다).
  final bool phoneRequired;

  @override
  State<ChurchInfoFields> createState() => _ChurchInfoFieldsState();
}

class _ChurchInfoFieldsState extends State<ChurchInfoFields> {
  final _addressField = GlobalKey<FormFieldState<String>>();
  String? _searchError;

  Future<void> _searchAddress() async {
    setState(() => _searchError = null);
    try {
      final result = await searchRoadAddress();
      if (result == null || !mounted) return;
      setState(() => widget.address.text = result.roadAddress);
      // 주소를 고르면 이전에 떠 있던 "주소를 입력해 주세요" 오류를 지운다.
      _addressField.currentState?.didChange(widget.address.text);
      _addressField.currentState?.validate();
    } catch (e) {
      if (mounted) setState(() => _searchError = '$e');
    }
  }

  String? _validatePhone(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return widget.phoneRequired ? '전화번호를 입력해 주세요' : null;
    return isValidKoreanPhone(text) ? null : '전화번호 형식이 올바르지 않습니다';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.name,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: '교회 이름'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? '교회 이름을 입력해 주세요' : null,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: const [KoreanPhoneFormatter()],
          decoration: InputDecoration(
            labelText: widget.phoneRequired ? '교회 전화번호' : '교회 전화번호 (선택)',
            hintText: '02-1234-5678',
          ),
          validator: _validatePhone,
        ),
        const SizedBox(height: 16),
        // 오류 문구는 입력창 바깥(아래)에 따로 보여준다. 그래야 오류가 떠도
        // 입력창과 검색 버튼의 높이가 서로 같게 유지된다.
        FormField<String>(
          key: _addressField,
          validator: (_) =>
              widget.address.text.trim().isEmpty ? '주소를 입력해 주세요' : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 버튼을 입력창과 같은 높이로 늘린다 (높이를 숫자로 고정하지 않는다).
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.address,
                        // 검색으로 고른 주소만 쓰도록 직접 수정은 막는다. 검색을 못 쓰는 플랫폼은 직접 입력.
                        readOnly: isAddressSearchSupported,
                        onTap:
                            isAddressSearchSupported &&
                                widget.address.text.isEmpty
                            ? _searchAddress
                            : null,
                        onChanged: (_) => state.didChange(widget.address.text),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(200),
                        ],
                        decoration: InputDecoration(
                          labelText: '교회 주소',
                          hintText: isAddressSearchSupported
                              ? '주소 검색을 눌러 도로명 주소를 선택하세요'
                              : '도로명 주소를 입력하세요',
                        ),
                      ),
                    ),
                    if (isAddressSearchSupported) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _searchAddress,
                        icon: const Icon(Icons.search, size: 18),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _searchError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
