import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('SmartFormField supports package-independent custom fields', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<int>(
              name: 'quantity',
              initialValue: 1,
              builder: (context, field) {
                return TextButton(
                  onPressed: () => field.didChange(7),
                  child: Text('Quantity: ${field.value}'),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text('Quantity: 1'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(find.text('Quantity: 7'), findsOneWidget);
    expect(controller.valueOf<int>('quantity'), 7);
  });

  testWidgets('SmartTextField renders the first synchronous error', (
    tester,
  ) async {
    final formKey = SmartFormKey();

    await tester.pumpWidget(
      _app(
        SmartForm(
          key: formKey,
          children: <Widget>[
            SmartTextField(
              name: 'email',
              decoration: const InputDecoration(labelText: 'Email'),
              validators: <SmartValidator<String>>[
                (value) => value == null || value.trim().isEmpty
                    ? 'Email is required'
                    : null,
                (value) => value!.contains('@') ? null : 'Invalid email',
              ],
            ),
          ],
        ),
      ),
    );

    final result = await formKey.validate();
    await tester.pumpAndSettle();

    expect(result.isValid, isFalse);
    expect(result.errors, <String, String>{'email': 'Email is required'});
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.errorText,
      'Email is required',
    );
    expect(find.text('Email is required'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
  });

  testWidgets('exposes validating state and waits for async validation', (
    tester,
  ) async {
    final controller = SmartFormController();
    final completion = Completer<String?>();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: 'username',
              initialValue: 'taken',
              asyncValidators: <SmartAsyncValidator<String>>[
                (_) => completion.future,
              ],
              builder: (context, field) {
                return Text(
                  field.isValidating
                      ? 'Validating'
                      : field.errorText ?? 'Ready',
                );
              },
            ),
          ],
        ),
      ),
    );

    final validation = controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pump();
    expect(find.text('Validating'), findsOneWidget);

    completion.complete('Username is already used');
    final result = await validation;
    await tester.pump();

    expect(result.isValid, isFalse);
    expect(find.text('Username is already used'), findsOneWidget);
  });

  testWidgets('ignores an outdated asynchronous validation result', (
    tester,
  ) async {
    final controller = SmartFormController();
    final oldResult = Completer<String?>();
    final newResult = Completer<String?>();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: 'username',
              initialValue: 'old',
              asyncValidators: <SmartAsyncValidator<String>>[
                (value) => value == 'old' ? oldResult.future : newResult.future,
              ],
              builder: (context, field) => Text(field.errorText ?? 'Valid'),
            ),
          ],
        ),
      ),
    );

    final oldValidation = controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    controller.setValue<String>('username', 'new');
    final latestValidation = controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );

    newResult.complete(null);
    expect((await latestValidation).isValid, isTrue);
    oldResult.complete('Stale error');
    expect((await oldValidation).isValid, isTrue);
    await tester.pump();

    expect(find.text('Stale error'), findsNothing);
    expect(find.text('Valid'), findsOneWidget);
  });

  testWidgets('patchValue and reset synchronize SmartTextField text', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: const <Widget>[
            SmartTextField(name: 'name', initialValue: 'Initial'),
          ],
        ),
      ),
    );

    controller.patchValue(<String, Object?>{'name': 'Patched'});
    await tester.pump();
    expect(find.text('Patched'), findsOneWidget);

    controller.reset();
    await tester.pump();
    expect(find.text('Initial'), findsOneWidget);
    expect(controller.valueOf<String>('name'), 'Initial');
  });

  testWidgets('server errors render and clear after editing', (tester) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: const <Widget>[SmartTextField(name: 'email')],
        ),
      ),
    );

    controller.setFieldError('email', 'Already registered');
    await tester.pump();
    expect(find.text('Already registered'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.pump();
    expect(find.text('Already registered'), findsNothing);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}
