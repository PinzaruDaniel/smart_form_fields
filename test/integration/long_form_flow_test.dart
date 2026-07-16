import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('corrects and submits a long registration form', (tester) async {
    final controller = SmartFormController();
    final scrollController = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SmartForm(
                  controller: controller,
                  autovalidateMode: AutovalidateMode.disabled,
                  children: <Widget>[
                    for (var index = 0; index < 12; index++) ...<Widget>[
                      SmartTextField(
                        name: 'field_$index',
                        initialValue: index < 9 ? 'Value $index' : null,
                        decoration: InputDecoration(labelText: 'Field $index'),
                        validators: <SmartValidator<String>>[
                          SmartValidators.required<String>(
                            message: 'Field $index is required',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final firstValidation = controller.validate();
    await tester.pumpAndSettle();
    final firstResult = await firstValidation;

    expect(firstResult.isValid, isFalse);
    expect(firstResult.errors.keys, <String>[
      'field_9',
      'field_10',
      'field_11',
    ]);
    expect(scrollController.offset, greaterThan(0));
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Field 9'))
          .focusNode!
          .hasFocus,
      isTrue,
    );

    for (var index = 9; index < 12; index++) {
      await tester.enterText(
        find.widgetWithText(TextField, 'Field $index'),
        'Value $index',
      );
    }

    final finalResult = await controller.validate();
    await tester.pumpAndSettle();

    expect(finalResult.isValid, isTrue);
    expect(finalResult.errors, isEmpty);
    expect(finalResult.values.length, 12);
    expect(finalResult.values['field_11'], 'Value 11');
  });
}
