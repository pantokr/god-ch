import 'package:flutter/material.dart';

import '../theme.dart';

/// 고르기 칸. 모든 화면에서 같은 높이·테두리·화살표로 보이도록 드롭다운은 이것만 쓴다.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.menuMaxHeight = 320,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  /// 이름표 앞 아이콘 (없으면 생략).
  final IconData? icon;
  final double menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: menuMaxHeight,
      borderRadius: BorderRadius.circular(AppRadius.card),
      icon: const Icon(Icons.expand_more),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

/// 목록 위에 놓는 검색 칸. 돋보기 아이콘과 안내 글자가 항상 같다.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.autofocus = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
      ),
    );
  }
}
