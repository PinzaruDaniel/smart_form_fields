import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('matchesField revalidates after its source changes', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          autovalidateMode: AutovalidateMode.disabled,
          scrollToFirstError: false,
          focusFirstError: false,
          errorAnimation: SmartErrorAnimation.none,
          children: <Widget>[
            const SmartPasswordField(
              name: 'password',
              initialValue: 'secret',
              minLength: null,
            ),
            SmartPasswordField(
              name: 'confirm_password',
              initialValue: 'secret',
              minLength: null,
              validators: <SmartValidator<String>>[
                SmartValidators.matchesField<String>(
                  'password',
                  message: 'Passwords do not match',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect((await controller.validate()).isValid, isTrue);

    controller.setValue<String>('password', 'changed');
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);

    controller.setValue<String>('password', 'secret');
    await tester.pump();
    expect(find.text('Passwords do not match'), findsNothing);
  });

  testWidgets('dependency changes do not show errors before first validation', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          autovalidateMode: AutovalidateMode.disabled,
          children: <Widget>[
            const SmartTextField(name: 'source', initialValue: 'one'),
            SmartTextField(
              name: 'dependent',
              initialValue: 'different',
              validators: <SmartValidator<String>>[
                SmartValidators.matchesField<String>('source'),
              ],
            ),
          ],
        ),
      ),
    );

    controller.setValue<String>('source', 'two');
    await tester.pump();

    expect(find.text('Values do not match.'), findsNothing);
  });

  testWidgets('requiredWhen supports typed source values', (tester) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          autovalidateMode: AutovalidateMode.disabled,
          scrollToFirstError: false,
          focusFirstError: false,
          errorAnimation: SmartErrorAnimation.none,
          children: <Widget>[
            SmartFormField<_AccountType>(
              name: 'account_type',
              initialValue: _AccountType.personal,
              builder: (context, field) => Text(field.value!.name),
            ),
            SmartTextField(
              name: 'company_name',
              validators: <SmartValidator<String>>[
                SmartValidators.requiredWhen<String>(
                  field: 'account_type',
                  equals: _AccountType.business,
                  message: 'Company name is required',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect((await controller.validate()).isValid, isTrue);

    controller.setValue<_AccountType>('account_type', _AccountType.business);
    await tester.pump();

    expect(find.text('Company name is required'), findsOneWidget);
  });

  testWidgets('custom dependent validator receives a read-only snapshot', (
    tester,
  ) async {
    final controller = SmartFormController();
    var rejectedMutation = false;

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          scrollToFirstError: false,
          focusFirstError: false,
          children: <Widget>[
            const SmartTextField(name: 'country', initialValue: 'md'),
            SmartTextField(
              name: 'city',
              initialValue: 'Chisinau',
              validators: <SmartValidator<String>>[
                SmartValidators.dependent<String>(
                  dependsOn: const <String>['country'],
                  validator: (value, context) {
                    try {
                      context.values['country'] = 'ro';
                    } on UnsupportedError {
                      rejectedMutation = true;
                    }
                    return context.valueOf<String>('country') == 'md' &&
                            value == 'Chisinau'
                        ? null
                        : 'Invalid city';
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final result = await controller.validate();

    expect(result.isValid, isTrue);
    expect(rejectedMutation, isTrue);
  });

  testWidgets('async dependency revalidation discards stale results', (
    tester,
  ) async {
    final controller = SmartFormController();
    final requests = <String, Completer<String?>>{};

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          autovalidateMode: AutovalidateMode.disabled,
          scrollToFirstError: false,
          focusFirstError: false,
          errorAnimation: SmartErrorAnimation.none,
          children: <Widget>[
            const SmartTextField(name: 'source', initialValue: 'initial'),
            SmartFormField<String>(
              name: 'dependent',
              initialValue: 'value',
              asyncValidators: <SmartAsyncValidator<String>>[
                SmartAsyncValidators.dependent<String>(
                  dependsOn: const <String>['source'],
                  validator: (value, context) {
                    final source = context.valueOf<String>('source')!;
                    final completion = Completer<String?>();
                    requests[source] = completion;
                    return completion.future;
                  },
                ),
              ],
              builder: (context, field) => Text(
                field.errorText ??
                    (field.isValidating ? 'Validating' : 'Ready'),
              ),
            ),
          ],
        ),
      ),
    );

    final initialValidation = controller.validate();
    await tester.pump();
    requests['initial']!.complete(null);
    await tester.pump();
    expect((await initialValidation).isValid, isTrue);

    controller.setValue<String>('source', 'old');
    await tester.pump();
    controller.setValue<String>('source', 'new');
    await tester.pump();

    requests['new']!.complete(null);
    await tester.pump();
    requests['old']!.complete('Stale dependency error');
    await tester.pump();

    expect(find.text('Stale dependency error'), findsNothing);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('patchValue revalidates one dependent against final values', (
    tester,
  ) async {
    final controller = SmartFormController();
    var validations = 0;

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          autovalidateMode: AutovalidateMode.disabled,
          scrollToFirstError: false,
          focusFirstError: false,
          children: <Widget>[
            const SmartTextField(name: 'first', initialValue: 'a'),
            const SmartTextField(name: 'second', initialValue: 'b'),
            SmartTextField(
              name: 'summary',
              initialValue: 'ab',
              validators: <SmartValidator<String>>[
                SmartValidators.dependent<String>(
                  dependsOn: const <String>['first', 'second'],
                  validator: (value, context) {
                    validations++;
                    final expected =
                        '${context.valueOf<String>('first')}'
                        '${context.valueOf<String>('second')}';
                    return value == expected ? null : 'Invalid summary';
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect((await controller.validate()).isValid, isTrue);
    expect(validations, 1);

    controller.patchValue(<String, Object?>{
      'first': 'x',
      'second': 'y',
      'summary': 'xy',
    });
    await tester.pump();

    expect(validations, 2);
    expect(find.text('Invalid summary'), findsNothing);
  });

  testWidgets('rejects unknown dependency names during form validation', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartTextField(
              name: 'dependent',
              validators: <SmartValidator<String>>[
                SmartValidators.matchesField<String>('missing'),
              ],
            ),
          ],
        ),
      ),
    );

    await expectLater(
      controller.validate(),
      throwsA(
        isA<FlutterError>().having(
          (error) => error.toString(),
          'message',
          contains('No field named "missing"'),
        ),
      ),
    );
  });

  testWidgets('detects dependency cycles with the complete path', (
    tester,
  ) async {
    final controller = SmartFormController();
    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartTextField(
              name: 'first',
              validators: <SmartValidator<String>>[
                SmartValidators.matchesField<String>('second'),
              ],
            ),
            SmartTextField(
              name: 'second',
              validators: <SmartValidator<String>>[
                SmartValidators.matchesField<String>('first'),
              ],
            ),
          ],
        ),
      ),
    );

    await expectLater(
      controller.validate(),
      throwsA(
        isA<FlutterError>()
            .having(
              (error) => error.toString(),
              'summary',
              contains('dependency cycle'),
            )
            .having(
              (error) => error.toString(),
              'path',
              anyOf(
                contains('first -> second -> first'),
                contains('second -> first -> second'),
              ),
            ),
      ),
    );
  });

  testWidgets('JSON supports snake_case dependent validator definitions', (
    tester,
  ) async {
    final controller = SmartFormController();
    var asyncCalls = 0;

    await tester.pumpWidget(
      _app(
        SmartJsonForm.fromJson(
          controller: controller,
          autovalidateMode: AutovalidateMode.disabled,
          json: const <String, Object?>{
            'scroll_to_first_error': false,
            'focus_first_error': false,
            'error_animation': 'none',
            'fields': <Object?>[
              <String, Object?>{
                'type': 'password',
                'name': 'password',
                'initial_value': 'secret',
              },
              <String, Object?>{
                'type': 'password',
                'name': 'confirm_password',
                'initial_value': 'wrong',
                'validators': <Object?>[
                  <String, Object?>{
                    'type': 'matches_field',
                    'field': 'password',
                    'message': 'Passwords do not match',
                  },
                ],
              },
              <String, Object?>{
                'type': 'text',
                'name': 'account_type',
                'initial_value': 'personal',
              },
              <String, Object?>{
                'type': 'text',
                'name': 'company_name',
                'validators': <Object?>[
                  <String, Object?>{
                    'type': 'required_when',
                    'field': 'account_type',
                    'equals': 'business',
                    'message': 'Company name is required',
                  },
                ],
              },
              <String, Object?>{
                'type': 'text',
                'name': 'validation_mode',
                'initial_value': 'normal',
              },
              <String, Object?>{
                'type': 'text',
                'name': 'username',
                'initial_value': 'ana',
                'async_validators': <Object?>[
                  <String, Object?>{
                    'name': 'username_available',
                    'depends_on': <Object?>['validation_mode'],
                  },
                ],
              },
            ],
          },
          asyncValidators: <String, SmartAsyncValidator<Object?>>{
            'username_available': (value) async {
              asyncCalls++;
              return null;
            },
          },
        ),
      ),
    );

    final invalid = await controller.validate();
    expect(invalid.errors['confirm_password'], 'Passwords do not match');
    expect(invalid.errors.containsKey('company_name'), isFalse);

    controller.setValue<String>('confirm_password', 'secret');
    expect((await controller.validate()).isValid, isTrue);

    controller.setValue<String>('account_type', 'business');
    await tester.pump();
    expect(find.text('Company name is required'), findsOneWidget);

    final callsBeforeDependencyChange = asyncCalls;
    controller.setValue<String>('validation_mode', 'strict');
    await tester.pump();
    expect(asyncCalls, callsBeforeDependencyChange + 1);
  });
}

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

enum _AccountType { personal, business }
