import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 입력란을 벗어날 때(포커스를 잃을 때)부터 그 입력란만 검사해서 오류 문구를 보여주는 입력란.
/// 처음 입력하는 동안에는 오류가 보이지 않고, 한 번 벗어난 뒤에는 고칠 때마다 바로 다시 검사한다.
/// 제출할 때는 바깥 [Form]의 validate로 모든 입력란이 한꺼번에 검사된다.
class BlurValidatedField extends StatefulWidget {
  const BlurValidatedField({
    super.key,
    required this.controller,
    required this.decoration,
    this.validator,
    this.obscureText = false,
    this.autocorrect = true,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool autocorrect;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  State<BlurValidatedField> createState() => _BlurValidatedFieldState();
}

class _BlurValidatedFieldState extends State<BlurValidatedField> {
  // 별도 Focus 위젯을 감싸면 Tab 이동 때 한 칸을 더 거치므로, 입력란 자신의 포커스를 직접 듣는다.
  final _focus = FocusNode();
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  /// 입력란에서 벗어나는 순간부터 이 입력란만 검사한다.
  void _onFocus() {
    if (!_focus.hasFocus && !_left) setState(() => _left = true);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focus,
      controller: widget.controller,
      decoration: widget.decoration,
      validator: widget.validator,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      autovalidateMode: _left
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
    );
  }
}
