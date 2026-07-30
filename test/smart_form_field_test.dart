import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('SmartSubmitButton submits valid forms once and clears drafts', (
    tester,
  ) async {
    final controller = SmartFormController();
    final storage = SmartMemoryDraftStorage();
    final draft = SmartFormDraftController(
      id: 'submit-profile',
      storage: storage,
      autosaveDebounce: Duration.zero,
    );
    final completer = Completer<void>();
    var submitCount = 0;
    Map<String, Object?>? submittedValues;

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          draftController: draft,
          onSubmit: (values) {
            submitCount++;
            submittedValues = values;
            return completer.future;
          },
          children: <Widget>[
            SmartTextField(
              name: 'email',
              decoration: const InputDecoration(labelText: 'Email'),
              validators: <SmartValidator>[SmartValidators.required()],
            ),
            SmartSubmitButton(
              controller: controller,
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'person@example.com',
    );
    await tester.pump();
    await tester.pump();
    expect(await storage.read('submit-profile'), isNotNull);

    await tester.tap(find.text('Create account'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(controller.isSubmitting, isTrue);
    expect(submitCount, 1);

    completer.complete();
    await tester.pumpAndSettle();

    expect(controller.isSubmitting, isFalse);
    expect(submittedValues, <String, Object?>{'email': 'person@example.com'});
    expect(await storage.read('submit-profile'), isNull);

    draft.dispose();
    controller.dispose();
  });

  testWidgets('SmartSubmitButton validates without submitting invalid forms', (
    tester,
  ) async {
    final controller = SmartFormController();
    var submitCount = 0;

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          onSubmit: (_) => submitCount++,
          children: <Widget>[
            SmartTextField(
              name: 'email',
              decoration: const InputDecoration(labelText: 'Email'),
              validators: <SmartValidator>[SmartValidators.required()],
            ),
            SmartSubmitButton(
              controller: controller,
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(submitCount, 0);
    expect(find.text('This field is required.'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('SmartConditionalField shows and unregisters dependent child', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartDropdownField<String>(
              name: 'account_type',
              items: <String>['personal', 'business'],
              itemLabelBuilder: (value) => value,
              decoration: const InputDecoration(labelText: 'Account type'),
            ),
            SmartConditionalField(
              dependsOn: 'account_type',
              condition: (value, _) => value == 'business',
              child: const SmartTextField(
                name: 'company_name',
                decoration: InputDecoration(labelText: 'Company name'),
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.widgetWithText(TextField, 'Company name'), findsNothing);
    expect(controller.values.containsKey('company_name'), isFalse);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('business').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Company name'), findsOneWidget);
    expect(controller.values.containsKey('company_name'), isTrue);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('personal').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Company name'), findsNothing);
    expect(controller.values.containsKey('company_name'), isFalse);

    controller.dispose();
  });

  testWidgets('SmartConditionalField animates visibility changes', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartDropdownField<String>(
              name: 'account_type',
              items: const <String>['personal', 'business'],
              itemLabelBuilder: (value) => value,
              decoration: const InputDecoration(labelText: 'Account type'),
            ),
            SmartConditionalField(
              dependsOn: 'account_type',
              duration: const Duration(milliseconds: 300),
              condition: (value, _) => value == 'business',
              child: const SmartTextField(
                name: 'company_name',
                decoration: InputDecoration(labelText: 'Company name'),
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.widgetWithText(TextField, 'Company name'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('business').last);
    await tester.pump();

    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(AnimatedSize), findsWidgets);
    expect(find.widgetWithText(TextField, 'Company name'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(controller.values.containsKey('company_name'), isTrue);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('personal').last);
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Company name'), findsOneWidget);
    expect(controller.values.containsKey('company_name'), isTrue);

    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Company name'), findsNothing);
    expect(controller.values.containsKey('company_name'), isFalse);

    controller.dispose();
  });

  testWidgets('SmartConditionalField does not clip focused outlined labels', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartDropdownField<String>(
              name: 'account_type',
              items: const <String>['personal', 'business'],
              itemLabelBuilder: (value) => value,
              decoration: const InputDecoration(labelText: 'Account type'),
            ),
            SmartConditionalField(
              dependsOn: 'account_type',
              condition: (value, _) => value == 'business',
              child: const SmartTextField(
                name: 'company_name',
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Company legal name',
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('business').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextField, 'Company legal name'));
    await tester.pumpAndSettle();

    final animatedSizes = tester.widgetList<AnimatedSize>(
      find.descendant(
        of: find.byType(SmartConditionalField),
        matching: find.byType(AnimatedSize),
      ),
    );
    expect(animatedSizes.single.clipBehavior, Clip.none);

    final stacks = tester.widgetList<Stack>(
      find.descendant(
        of: find.byType(SmartConditionalField),
        matching: find.byType(Stack),
      ),
    );
    expect(stacks.single.clipBehavior, Clip.none);
    expect(find.text('Company legal name'), findsOneWidget);

    controller.dispose();
  });

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
              validators: <SmartValidator>[
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

    final validation = formKey.validate();
    await tester.pumpAndSettle();
    final result = await validation;

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

  testWidgets('validates on focus loss instead of while typing by default', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartTextField(
              name: 'email',
              decoration: const InputDecoration(labelText: 'Email'),
              validators: <SmartValidator>[
                SmartValidators.email(message: 'Invalid email'),
              ],
            ),
            const SmartTextField(
              name: 'next',
              decoration: InputDecoration(labelText: 'Next field'),
            ),
          ],
        ),
      ),
    );

    final emailField = find.widgetWithText(TextField, 'Email');
    await tester.tap(emailField);
    await tester.enterText(emailField, 'invalid');
    await tester.pump();

    expect(find.text('Invalid email'), findsNothing);

    await tester.tap(find.widgetWithText(TextField, 'Next field'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email'), findsOneWidget);
  });

  testWidgets('explicit form validation validates the focused field', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartTextField(
              name: 'password',
              decoration: const InputDecoration(labelText: 'Password'),
              validators: <SmartValidator>[
                SmartValidators.minLength(
                  8,
                  message: 'Use at least 8 characters',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final passwordField = find.byType(TextField);
    await tester.tap(passwordField);
    await tester.enterText(passwordField, 'short');
    await tester.pump();
    expect(find.text('Use at least 8 characters'), findsNothing);

    final result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pumpAndSettle();

    expect(result.isValid, isFalse);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('parent rebuild does not validate an on-unfocus field in focus', (
    tester,
  ) async {
    late StateSetter rebuildHost;
    var error = 'Initial error';

    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuildHost = setState;
            return SmartForm(
              children: <Widget>[
                SmartTextField(
                  name: 'phone',
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validators: <SmartValidator>[(value) => error],
                ),
                const SmartTextField(
                  name: 'next',
                  decoration: InputDecoration(labelText: 'Next field'),
                ),
              ],
            );
          },
        ),
      ),
    );

    final phoneField = find.widgetWithText(TextField, 'Phone');
    await tester.tap(phoneField);
    await tester.enterText(phoneField, '123');
    rebuildHost(() => error = 'Updated error');
    await tester.pump();

    expect(find.text('Initial error'), findsNothing);
    expect(find.text('Updated error'), findsNothing);

    await tester.tap(find.widgetWithText(TextField, 'Next field'));
    await tester.pumpAndSettle();
    expect(find.text('Updated error'), findsOneWidget);
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
              validators: <SmartValidator>[(value) => error],
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
              validators: <SmartValidator>[(value) => 'Invalid value'],
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
