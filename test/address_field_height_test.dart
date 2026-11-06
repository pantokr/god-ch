import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/address_input.dart';
import 'package:god_ch/core/widgets/blur_validated_field.dart';
import 'package:god_ch/core/widgets/labeled_field.dart';

void main() {
  testWidgets('주소 칸과 다른 입력칸의 높이가 같다', (tester) async {
    final address = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LabeledField(
                    label: '이름',
                    child: BlurValidatedField(
                      key: const Key('name'),
                      controller: TextEditingController(),
                      maxLength: 50,
                      decoration: const InputDecoration(),
                    ),
                  ),
                  AddressInput(controller: address),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final name = tester.getSize(find.byKey(const Key('name'))).height;
    final fields = find.descendant(
      of: find.byType(AddressInput),
      matching: find.byType(TextField),
    );
    final main = tester.getSize(fields.at(0)).height;
    final sub = tester.getSize(fields.at(1)).height;
    // ignore: avoid_print
    print('이름 $name · 기본 주소 $main · 상세 주소 $sub');
    expect(main, name);
    expect(sub, name);
  });
}
