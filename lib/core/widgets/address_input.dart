import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address/address_search.dart';
import '../icons.dart';
import '../theme.dart';
import 'labeled_field.dart';

/// 주소 입력란: 위는 기본 주소(도로명 주소 검색 결과), 아래는 상세 주소(동 · 호수 같은 주소) 두 칸이다.
/// 검색은 글자 없는 아이콘 버튼이고, 기본 주소 칸을 눌러도 열린다.
/// 바깥에는 두 칸을 합친 한 줄([join])이 [controller]에 담긴다 (저장 형식은 그대로 문자열 하나).
/// 바깥 [Form] 안에 놓는다. 검사는 바깥 [FormField]가 하고, 값이 바뀔 때마다 [onChanged]가 불린다.
class AddressInput extends StatefulWidget {
  const AddressInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.required = false,
    this.onChanged,
    this.onSearched,
    this.onError,
  });

  /// 기본 주소와 상세 주소를 합친 주소.
  final TextEditingController controller;

  /// false이면 볼 수만 있다 (비어 있으면 "미제공").
  final bool enabled;
  final bool required;

  /// 직접 입력하거나 검색으로 고를 때마다.
  final VoidCallback? onChanged;

  /// 검색으로 주소를 골랐을 때 (바깥에서 오류 표시를 지우는 데 쓴다).
  final VoidCallback? onSearched;

  /// 검색 창을 열지 못했을 때.
  final ValueChanged<String>? onError;

  /// 저장 형식: 기본 주소와 상세 주소 사이를 이 글자로 가른다.
  static const separator = ' / ';

  static String join(String main, String sub) {
    final m = main.trim();
    final s = sub.trim();
    return s.isEmpty ? m : '$m$separator$s';
  }

  /// [join]한 주소를 기본 주소와 상세 주소로 되돌린다. 구분이 없던 예전 주소는 모두 기본 주소다.
  static (String, String) split(String full) {
    final i = full.indexOf(separator);
    if (i < 0) return (full, '');
    return (full.substring(0, i), full.substring(i + separator.length));
  }

  @override
  State<AddressInput> createState() => _AddressInputState();
}

class _AddressInputState extends State<AddressInput> {
  late final TextEditingController _main;
  late final TextEditingController _sub;

  @override
  void initState() {
    super.initState();
    final (main, sub) = AddressInput.split(widget.controller.text);
    _main = TextEditingController(text: main);
    _sub = TextEditingController(text: sub);
  }

  @override
  void dispose() {
    _main.dispose();
    _sub.dispose();
    super.dispose();
  }

  void _emit() {
    widget.controller.text = AddressInput.join(_main.text, _sub.text);
    widget.onChanged?.call();
  }

  Future<void> _search() async {
    try {
      final result = await searchRoadAddress(context);
      if (result == null || !mounted) return;
      setState(() => _main.text = result.roadAddress);
      _emit();
      widget.onSearched?.call();
    } catch (e) {
      widget.onError?.call('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = isAddressSearchSupported && widget.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 기본 주소 + 검색 아이콘 버튼. 줄 높이는 입력칸 높이로 고정한다 (버튼 안의 LayoutBuilder는 IntrinsicHeight를 못 쓴다).
        LabeledField(
          label: '주소',
          required: widget.required,
          child: SizedBox(
            height: AppField.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _main,
                    enabled: widget.enabled,
                    // 검색을 쓸 수 있으면 기본 주소는 검색으로만 고른다. 못 쓰는 플랫폼은 직접 입력.
                    readOnly: canSearch,
                    onTap: canSearch ? _search : null,
                    onChanged: (_) => _emit(),
                    inputFormatters: [LengthLimitingTextInputFormatter(150)],
                    decoration: InputDecoration(
                      hintText: !widget.enabled
                          ? '미제공'
                          : canSearch
                          ? '기본 주소'
                          : '도로명 주소',
                    ),
                  ),
                ),
                if (canSearch) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: '주소 검색',
                    child: OutlinedButton(
                      onPressed: _search,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(AppField.height, 0),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(AppIcons.magnifyingGlass, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        AppField.spacer,
        // 상세 주소: 동 · 호수 같은 주소.
        LabeledField(
          label: '상세 주소',
          child: TextField(
            controller: _sub,
            enabled: widget.enabled,
            onChanged: (_) => _emit(),
            inputFormatters: [LengthLimitingTextInputFormatter(48)],
            decoration: InputDecoration(
              hintText: widget.enabled ? '상세 주소' : '미제공',
            ),
          ),
        ),
      ],
    );
  }
}
