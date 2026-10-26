import 'package:flutter/material.dart';

/// 입력란 이름. [required]면 이름 뒤에 별(*)을 붙여 필수 입력임을 나타낸다.
/// `InputDecoration(label: RequiredLabel('이름', required: true))`처럼 labelText 대신 쓴다.
class RequiredLabel extends StatelessWidget {
  const RequiredLabel(this.text, {super.key, this.required = true});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    if (!required) return Text(text);
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}
