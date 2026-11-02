import 'package:flutter/material.dart';

import '../theme.dart';
import 'labeled_field.dart';

/// [ChoiceRow]의 선택지 하나.
class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label, {this.enabled = true});

  final T value;
  final String label;
  final bool enabled;
}

/// 둘 중 하나를 고르는 칸: 이름표는 왼쪽에, 선택지는 오른쪽에 라디오 버튼으로 한 행에 나란히 놓인다.
/// 체크박스나 스위치 대신 양자택일에는 이것을 쓴다. [onChanged]가 null이면 눌리지 않는다.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final bool required;
  final List<ChoiceOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => LabeledField(
    label: label,
    required: required,
    child: ChoiceRadios<T>(
      options: options,
      value: value,
      onChanged: onChanged,
    ),
  );
}

/// 켬 / 끔 한 칸: 설정 이름은 왼쪽에, "켬 · 끔" 라디오 버튼은 오른쪽에 한 행으로 놓인다.
/// 체크박스 대신 쓴다. [indent]면 딸린 세부 설정으로 안으로 들여 쓴다.
class OnOffRow extends StatelessWidget {
  const OnOffRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.indent = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 28 : 0),
      child: Row(
        children: [
          // 눌리지 않는 종속 설정은 이름도 흐리게 보인다.
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: onChanged == null
                    ? context.palette.muted.withValues(alpha: 0.6)
                    : null,
              ),
            ),
          ),
          SizedBox(
            width: 132,
            child: ChoiceRadios<bool>(
              options: const [
                ChoiceOption(true, '켬'),
                ChoiceOption(false, '끔'),
              ],
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// 선택지들을 한 행에 같은 폭으로 나란히 놓는 라디오 버튼 묶음.
class ChoiceRadios<T> extends StatelessWidget {
  const ChoiceRadios({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<ChoiceOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return RadioGroup<T>(
      groupValue: value,
      onChanged: (v) {
        if (v != null && onChanged != null) onChanged!(v);
      },
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.control),
                onTap: onChanged == null || !o.enabled
                    ? null
                    : () => onChanged!(o.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Radio<T>(
                          value: o.value,
                          enabled: onChanged != null && o.enabled,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          o.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onChanged == null || !o.enabled
                                ? palette.muted.withValues(alpha: 0.6)
                                : palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
