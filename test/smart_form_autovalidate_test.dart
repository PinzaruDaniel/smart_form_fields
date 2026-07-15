import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('form-level disabled mode validates only on explicit submit', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            autovalidateMode: AutovalidateMode.disabled,
            scrollToFirstError: false,
            focusFirstError: false,
            children: <Widget>[
              SmartTextField(
                name: 'first_name',
                decoration: const InputDecoration(labelText: 'First name'),
                validators: <SmartValidator<String>>[
                  SmartValidators.required<String>(
                    message: 'First name is required',
                  ),
                ],
              ),
              const SmartTextField(
                name: 'last_name',
                decoration: InputDecoration(labelText: 'Last name'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'First name'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextField, 'Last name'));
    await tester.pump();

    expect(find.text('First name is required'), findsNothing);

    final result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pump();

    expect(result.isValid, isFalse);
    expect(find.text('First name is required'), findsOneWidget);
  });

  testWidgets('field-level mode overrides the form default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            autovalidateMode: AutovalidateMode.disabled,
            children: <Widget>[
              SmartTextField(
                name: 'first_name',
                autovalidateMode: AutovalidateMode.onUnfocus,
                decoration: const InputDecoration(labelText: 'First name'),
                validators: <SmartValidator<String>>[
                  SmartValidators.required<String>(
                    message: 'First name is required',
                  ),
                ],
              ),
              const SmartTextField(
                name: 'last_name',
                decoration: InputDecoration(labelText: 'Last name'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'First name'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextField, 'Last name'));
    await tester.pump();

    expect(find.text('First name is required'), findsOneWidget);
  });
}
