import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  test('uses a string-first API and an explicit typed-value API', () {
    final SmartValidator stringValidator = SmartValidators.minLength(3);
    final SmartValueValidator<DateTime> dateValidator =
        SmartValueValidators.required<DateTime>();

    expect(stringValidator('abc'), isNull);
    expect(dateValidator(DateTime(2020)), isNull);
  });

  group('SmartValidators.required', () {
    final validator = SmartValueValidators.required<Object>();

    test('rejects null and empty values', () {
      expect(validator(null), 'This field is required.');
      expect(validator('  '), 'This field is required.');
      expect(validator(const <Object>[]), 'This field is required.');
      expect(validator(const <Object, Object>{}), 'This field is required.');
    });

    test('accepts non-empty values and supports a custom message', () {
      expect(validator('value'), isNull);
      expect(validator(0), isNull);
      expect(SmartValidators.required(message: 'Required')(''), 'Required');
    });
  });

  group('SmartValidators.email', () {
    final validator = SmartValidators.email();

    test('allows blank optional values', () {
      expect(validator(null), isNull);
      expect(validator('  '), isNull);
    });

    test('accepts plausible addresses and rejects malformed ones', () {
      expect(validator('person@example.com'), isNull);
      expect(validator(' person+tag@example.co.uk '), isNull);
      expect(validator('person@example'), 'Enter a valid email address.');
      expect(validator('@example.com'), 'Enter a valid email address.');
    });
  });

  group('SmartValidators length rules', () {
    test('validates exact, minimum, and maximum lengths', () {
      expect(SmartValidators.length(3)('abc'), isNull);
      expect(
        SmartValidators.length(3)('ab'),
        'Must contain exactly 3 characters.',
      );
      expect(SmartValueValidators.minLength<List<int>>(2)(<int>[1, 2]), isNull);
      expect(
        SmartValidators.minLength(3)('ab'),
        'Must contain at least 3 characters.',
      );
      expect(SmartValidators.maxLength(3)('abc'), isNull);
      expect(
        SmartValidators.maxLength(3)('abcd'),
        'Must contain at most 3 characters.',
      );
    });

    test('allows blank values and rejects unsupported value types', () {
      expect(SmartValidators.length(2)(null), isNull);
      expect(
        SmartValueValidators.length<int>(2)(12),
        'Must contain exactly 2 characters.',
      );
    });

    test('rejects negative limits immediately', () {
      expect(() => SmartValidators.length(-1), throwsArgumentError);
      expect(() => SmartValidators.minLength(-1), throwsArgumentError);
      expect(() => SmartValidators.maxLength(-1), throwsArgumentError);
    });
  });

  group('SmartValidators.pattern', () {
    final validator = SmartValidators.pattern(
      RegExp(r'^SFF-\d{3}$'),
      message: 'Use SFF-000 format',
    );

    test('allows blank optional values', () {
      expect(validator(null), isNull);
      expect(validator(''), isNull);
    });

    test('validates the supplied pattern', () {
      expect(validator('SFF-123'), isNull);
      expect(validator('SFF-12'), 'Use SFF-000 format');
    });
  });

  group('SmartValidators numeric rules', () {
    test('number accepts finite numbers and numeric strings', () {
      final validator = SmartValueValidators.number<Object>();
      expect(validator(12.5), isNull);
      expect(validator(' -12.5 '), isNull);
      expect(validator(null), isNull);
      expect(validator('not a number'), 'Enter a valid number.');
      expect(validator(double.nan), 'Enter a valid number.');
      expect(validator(double.infinity), 'Enter a valid number.');
    });

    test('min and max are inclusive and parse strings', () {
      final minimum = SmartValueValidators.min<Object>(18);
      final maximum = SmartValueValidators.max<Object>(65);

      expect(minimum(18), isNull);
      expect(minimum('17.9'), 'Enter a value greater than or equal to 18.');
      expect(maximum('65'), isNull);
      expect(maximum(66), 'Enter a value less than or equal to 65.');
      expect(minimum('invalid'), 'Enter a value greater than or equal to 18.');
    });
  });
}
