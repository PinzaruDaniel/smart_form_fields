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

  testWidgets('debounces change validation but not explicit validation', (
    tester,
  ) async {
    final controller = SmartFormController();
    var validationCount = 0;

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: 'username',
              asyncValidationDebounce: const Duration(milliseconds: 300),
              asyncValidators: <SmartAsyncValidator<String>>[
                (value) async {
                  validationCount++;
                  return null;
                },
              ],
              builder: (context, field) {
                return TextButton(
                  onPressed: () => field.didChange('new-name'),
                  child: Text(field.isValidating ? 'Validating' : 'Ready'),
                );
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text('Validating'), findsOneWidget);
    expect(validationCount, 0);

    await tester.pump(const Duration(milliseconds: 299));
    expect(validationCount, 0);

    final result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pump();
    expect(result.isValid, isTrue);
    expect(validationCount, 1);

    await tester.pump(const Duration(milliseconds: 1));
    expect(validationCount, 1);
  });

  testWidgets('builder can clear a server error explicitly', (tester) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: 'code',
              builder: (context, field) {
                return TextButton(
                  onPressed: field.clearError,
                  child: Text(field.errorText ?? 'No error'),
                );
              },
            ),
          ],
        ),
      ),
    );

    controller.setFieldError('code', 'Rejected');
    await tester.pump();
    expect(find.text('Rejected'), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text('No error'), findsOneWidget);
  });

  testWidgets('initial value updates only while the field is pristine', (
    tester,
  ) async {
    final controller = SmartFormController();

    Widget buildField(String initialValue) {
      return _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: 'nickname',
              initialValue: initialValue,
              builder: (context, field) {
                return TextButton(
                  onPressed: () => field.didChange('Edited'),
                  child: Text(field.value ?? ''),
                );
              },
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildField('First'));
    await tester.pumpWidget(buildField('Second'));
    expect(controller.valueOf<String>('nickname'), 'Second');

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    await tester.pumpWidget(buildField('Third'));

    expect(controller.valueOf<String>('nickname'), 'Edited');
    expect(find.text('Edited'), findsOneWidget);
  });

  testWidgets('does not dispose a caller-owned focus node', (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      _app(
        SmartForm(
          children: <Widget>[
            SmartFormField<String>(
              name: 'custom',
              focusNode: focusNode,
              builder: (context, field) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(_app(const SizedBox()));

    expect(() => focusNode.addListener(() {}), returnsNormally);
    focusNode.dispose();
  });

  testWidgets('revalidates touched fields when validators change', (
    tester,
  ) async {
    final controller = SmartFormController();

    Widget buildField(String error) {
      return _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: 'value',
              validators: <SmartValidator<String>>[(value) => error],
              builder: (context, field) => Text(field.errorText ?? 'Valid'),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildField('First error'));
    await controller.validate(scrollToError: false, focusFirstError: false);
    await tester.pump();
    expect(find.text('First error'), findsOneWidget);

    await tester.pumpWidget(buildField('Updated error'));
    await tester.pump();
    expect(find.text('Updated error'), findsOneWidget);
  });

  testWidgets('disabled fields preserve values and skip validation', (
    tester,
  ) async {
    final controller = SmartFormController();

    Widget buildField({required bool enabled}) {
      return _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: 'value',
              initialValue: 'preserved',
              enabled: enabled,
              validators: <SmartValidator<String>>[(value) => 'Invalid value'],
              builder: (context, field) => Text(field.errorText ?? 'No error'),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildField(enabled: true));
    await controller.validate(scrollToError: false, focusFirstError: false);
    await tester.pump();
    expect(find.text('Invalid value'), findsOneWidget);

    await tester.pumpWidget(buildField(enabled: false));
    final result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pump();

    expect(result.isValid, isTrue);
    expect(result.values, <String, Object?>{'value': 'preserved'});
    expect(find.text('No error'), findsOneWidget);
  });

  testWidgets('updates registration when a generic field name changes', (
    tester,
  ) async {
    final controller = SmartFormController();

    Widget buildField(String name) {
      return _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartFormField<String>(
              name: name,
              initialValue: 'value',
              builder: (context, field) => const SizedBox(),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildField('old'));
    await tester.pumpWidget(buildField('new'));

    expect(controller.values, <String, Object?>{'new': 'value'});
    expect(() => controller.valueOf<String>('old'), throwsArgumentError);
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
