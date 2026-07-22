import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('builds and validates standard fields from decoded JSON', (
    tester,
  ) async {
    final controller = SmartFormController();
    final json =
        jsonDecode('''
      {
        "scroll_to_first_error": false,
        "focus_first_error": false,
        "error_animation": "none",
        "fields": [
          {
            "type": "email",
            "name": "email",
            "label_text": "Email",
            "required": true,
            "required_message": "Email is required"
          },
          {
            "type": "text",
            "name": "username",
            "label_text": "Username",
            "initial_value": "ab",
            "validators": [
              {
                "type": "min_length",
                "value": 3,
                "message": "Username is too short"
              }
            ]
          },
          {
            "type": "password",
            "name": "password",
            "label_text": "Password",
            "autovalidate_mode": "on_unfocus",
            "min_length": 8,
            "min_length_message": "Use at least 8 characters"
          },
          {
            "type": "date",
            "name": "birthDate",
            "label_text": "Birth date",
            "first_date": "1900-01-01",
            "last_date": "2100-12-31"
          },
          {
            "type": "dropdown",
            "name": "country",
            "label_text": "Country",
            "required": true,
            "options": [
              {"value": "md", "label": "Moldova"},
              {"value": "ro", "label": "Romania"}
            ]
          }
        ]
      }
    ''')
            as Map<String, Object?>;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartSchemaForm.fromJson(json: json, controller: controller),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Birth date'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);

    final invalid = await controller.validate();
    await tester.pump();
    expect(invalid.isValid, isFalse);
    expect(invalid.errors['email'], 'Email is required');
    expect(invalid.errors['username'], 'Username is too short');

    final birthDate = DateTime(1990, 4, 12);
    controller.patchValue(<String, Object?>{
      'email': 'person@example.com',
      'username': 'person',
      'password': 'password123',
      'birthDate': birthDate,
      'country': 'md',
    });
    await tester.pump();

    final valid = await controller.validate();
    await tester.pump();
    expect(valid.isValid, isTrue);
    expect(valid.values['birthDate'], birthDate);
    expect(valid.values['country'], 'md');
  });

  testWidgets('builds and validates a form from API model classes', (
    tester,
  ) async {
    final controller = SmartFormController();
    const fields = <_ApiField>[
      _EmailField(name: 'email', label: 'Email', required: true),
      _PasswordField(name: 'password', label: 'Password', minLength: 8),
      _PasswordField(
        name: 'confirm_password',
        label: 'Confirm password',
        matchesField: 'password',
      ),
      _DropdownField(
        name: 'country',
        label: 'Country',
        options: <String>['md', 'ro'],
      ),
    ];

    SmartFieldDefinition mapField(_ApiField field) {
      return switch (field) {
        _EmailField field => SmartFieldDefinition.email(
          name: field.name,
          labelText: field.label,
          required: field.required,
          requiredMessage: 'Email is required',
        ),
        _PasswordField field => SmartFieldDefinition.password(
          name: field.name,
          labelText: field.label,
          required: true,
          minLength: field.minLength,
          minLengthMessage: 'Use at least 8 characters',
          validators: <SmartValidatorDefinition>[
            if (field.matchesField case final source?)
              SmartValidatorDefinition.matchesField(
                source,
                message: 'Passwords do not match',
              ),
          ],
        ),
        _DropdownField field => SmartFieldDefinition.dropdown(
          name: field.name,
          labelText: field.label,
          required: true,
          options: <SmartOptionDefinition>[
            for (final option in field.options)
              SmartOptionDefinition(value: option, label: option),
          ],
        ),
      };
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartSchemaForm.fromClasses<_ApiField>(
            fields: fields,
            fieldMapper: mapField,
            controller: controller,
            scrollToFirstError: false,
            focusFirstError: false,
            errorAnimation: SmartErrorAnimation.none,
          ),
        ),
      ),
    );

    final invalid = await controller.validate();
    await tester.pump();

    expect(invalid.errors['email'], 'Email is required');
    expect(invalid.errors['password'], 'This field is required.');
    expect(invalid.errors['country'], 'This field is required.');

    controller.patchValue(<String, Object?>{
      'email': 'person@example.com',
      'password': 'password123',
      'confirm_password': 'password123',
      'country': 'md',
    });
    await tester.pump();

    final valid = await controller.validate();
    expect(valid.isValid, isTrue);
    expect(valid.values['country'], 'md');
  });

  testWidgets('supports custom fields, validators, and named async checks', (
    tester,
  ) async {
    final controller = SmartFormController();
    var asyncCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartSchemaForm.fromJson(
            controller: controller,
            json: const <String, Object?>{
              'scroll_to_first_error': false,
              'focus_first_error': false,
              'fields': <Object?>[
                <String, Object?>{
                  'type': 'toggle',
                  'name': 'terms',
                  'initial_value': false,
                  'validators': <Object?>[
                    <String, Object?>{
                      'type': 'mustBeTrue',
                      'message': 'Accept the terms',
                    },
                  ],
                  'async_validators': <Object?>['termsAllowed'],
                },
              ],
            },
            customFieldBuilders: <String, SmartFieldDefinitionBuilder>{
              'toggle': (context, definition, validators, asyncValidators) {
                return SmartFormField<Object?>(
                  name: definition.name,
                  initialValue: definition.properties['initial_value'],
                  validators: validators,
                  asyncValidators: asyncValidators,
                  builder: (context, field) => SwitchListTile(
                    title: const Text('Accept terms'),
                    value: field.value == true,
                    onChanged: field.didChange,
                  ),
                );
              },
            },
            customValidatorBuilders: <String, SmartValidatorDefinitionBuilder>{
              'mustBeTrue': (definition) {
                return (value) => value == true ? null : definition.message;
              },
            },
            asyncValidators: <String, SmartAsyncValidator<Object?>>{
              'termsAllowed': (value) async {
                asyncCalls++;
                return null;
              },
            },
          ),
        ),
      ),
    );

    final invalid = await controller.validate();
    expect(invalid.errors['terms'], 'Accept the terms');
    expect(asyncCalls, 0);

    controller.setValue<Object?>('terms', true);
    await tester.pump();
    final valid = await controller.validate();

    expect(valid.isValid, isTrue);
    expect(valid.values['terms'], isTrue);
    expect(asyncCalls, 1);
  });

  test('rejects malformed schemas with useful paths', () {
    expect(
      () => SmartFormSchema.fromJson(const <String, Object?>{
        'fields': <Object?>[
          <String, Object?>{'type': 'text'},
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('fields[0].name'),
        ),
      ),
    );
  });

  test('keeps JSON-oriented names as schema API aliases', () {
    final SmartJsonValidatorDefinition validator =
        SmartJsonValidatorDefinition.required();
    final SmartJsonFieldDefinition field = SmartJsonFieldDefinition(
      name: 'name',
      type: 'text',
      validators: <SmartValidatorDefinition>[validator],
    );
    final SmartJsonForm form = SmartJsonForm(
      schema: SmartFormSchema(fields: <SmartFieldDefinition>[field]),
    );

    expect(form.schema.fields.single.name, 'name');
  });
}

sealed class _ApiField {
  const _ApiField({required this.name, required this.label});

  final String name;
  final String label;
}

final class _EmailField extends _ApiField {
  const _EmailField({
    required super.name,
    required super.label,
    required this.required,
  });

  final bool required;
}

final class _PasswordField extends _ApiField {
  const _PasswordField({
    required super.name,
    required super.label,
    this.minLength,
    this.matchesField,
  });

  final int? minLength;
  final String? matchesField;
}

final class _DropdownField extends _ApiField {
  const _DropdownField({
    required super.name,
    required super.label,
    required this.options,
  });

  final List<String> options;
}
