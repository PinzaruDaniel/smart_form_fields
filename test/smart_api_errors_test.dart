import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  group('SmartApiErrors.parse', () {
    test('parses a complete nested response with field message lists', () {
      final result = SmartApiErrors.parse(const <String, Object?>{
        'success': false,
        'message': 'Please correct the highlighted fields',
        'data': <String, Object?>{
          'errors': <String, Object?>{
            'email': <String>['Email is invalid', 'Email is already used'],
            'first_name': 'First name is required',
            'non_field_errors': <String>['Registration is unavailable'],
          },
        },
      });

      expect(result.fieldErrors['email'], <String>[
        'Email is invalid',
        'Email is already used',
      ]);
      expect(result.fieldErrors['first_name'], <String>[
        'First name is required',
      ]);
      expect(result.generalErrors, <String>[
        'Registration is unavailable',
        'Please correct the highlighted fields',
      ]);
    });

    test('parses object arrays, JSON API pointers, and GraphQL paths', () {
      final result = SmartApiErrors.parse(const <String, Object?>{
        'errors': <Object?>[
          <String, Object?>{'field': 'email', 'message': 'Email is invalid'},
          <String, Object?>{
            'source': <String, Object?>{'pointer': '/data/attributes/password'},
            'detail': 'Password is too short',
          },
          <String, Object?>{
            'path': <Object?>['register', 'phone'],
            'message': 'Phone is invalid',
          },
        ],
      });

      expect(result.fieldErrors['email'], <String>['Email is invalid']);
      expect(result.fieldErrors['password'], <String>['Password is too short']);
      expect(result.fieldErrors['phone'], <String>['Phone is invalid']);
    });

    test('parses FastAPI detail arrays and Spring default messages', () {
      final fastApi = SmartApiErrors.parse(const <String, Object?>{
        'detail': <Object?>[
          <String, Object?>{
            'type': 'missing',
            'loc': <Object?>['body', 'email'],
            'msg': 'Field required',
            'input': null,
          },
        ],
      });
      final spring = SmartApiErrors.parse(const <String, Object?>{
        'errors': <Object?>[
          <String, Object?>{
            'field': 'password',
            'defaultMessage': 'Password is too short',
            'rejectedValue': 'short',
            'bindingFailure': false,
          },
        ],
      });

      expect(fastApi.fieldErrors['email'], <String>['Field required']);
      expect(spring.fieldErrors['password'], <String>['Password is too short']);
      expect(spring.fieldErrors, hasLength(1));
    });

    test('parses a direct field-error map', () {
      final result = SmartApiErrors.parse(const <String, Object?>{
        'email': <String>['Invalid email'],
        'password': <String>['Too short'],
      });

      expect(result.hasErrors, isTrue);
      expect(result.fieldErrors.keys, <String>['email', 'password']);
    });

    test('does not treat a successful data response as validation errors', () {
      final result = SmartApiErrors.parse(const <String, Object?>{
        'success': true,
        'data': <String, Object?>{'email': 'person@example.com', 'name': 'Ana'},
      });

      expect(result.hasErrors, isFalse);
    });
  });

  testWidgets('maps parsed API errors onto registered form fields', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            errorAnimation: SmartErrorAnimation.none,
            children: const <Widget>[
              SmartTextField(name: 'firstName'),
              SmartEmailField(name: 'email'),
              SmartPhoneField(name: 'phone'),
            ],
          ),
        ),
      ),
    );

    final result = await controller.setErrorsFromResponse(
      const <String, Object?>{
        'status': 422,
        'message': 'Validation failed',
        'validation_errors': <String, Object?>{
          'first_name': <String>['First name is required'],
          'email': <String>['Email is invalid', 'Email is already used'],
          'profile.phone_number': <String>['Phone is invalid'],
          'unknown_field': <String>['Unknown value'],
        },
      },
      fieldAliases: const <String, String>{'profile.phone_number': 'phone'},
    );
    await tester.pump();

    expect(result.appliedErrors, <String, String>{
      'firstName': 'First name is required',
      'email': 'Email is invalid\nEmail is already used',
      'phone': 'Phone is invalid',
    });
    expect(result.unmappedFieldErrors['unknown_field'], <String>[
      'Unknown value',
    ]);
    expect(result.generalErrors, <String>['Validation failed']);
    expect(find.text('First name is required'), findsOneWidget);
    expect(
      find.text('Email is invalid\nEmail is already used'),
      findsOneWidget,
    );
    expect(find.text('Phone is invalid'), findsOneWidget);
  });

  testWidgets('supports a custom full-response extractor', (tester) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            children: const <Widget>[SmartTextField(name: 'code')],
          ),
        ),
      ),
    );

    final result = await controller.setErrorsFromResponse(
      const <String, Object?>{
        'payload': <String, Object?>{'problem': 'Rejected code'},
      },
      extractor: (response) {
        final map = response! as Map<String, Object?>;
        final payload = map['payload']! as Map<String, Object?>;
        return SmartApiErrorPayload(
          fieldErrors: <String, List<String>>{
            'code': <String>[payload['problem']! as String],
          },
        );
      },
    );
    await tester.pump();

    expect(result.appliedErrors['code'], 'Rejected code');
    expect(find.text('Rejected code'), findsOneWidget);
  });
}
