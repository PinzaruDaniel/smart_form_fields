import 'smart_validator.dart';
import 'smart_validation_context.dart';
import 'smart_validator_metadata.dart';

/// String-first factories for commonly used synchronous validators.
///
/// Validators other than [required] allow `null` and blank strings. Add a
/// [required] validator first when a field must contain a value.
abstract final class SmartValidators {
  /// Creates a string validator with explicit [dependsOn] metadata.
  static SmartValidator dependent({
    required Iterable<String> dependsOn,
    required SmartContextValidator<String> validator,
  }) {
    return SmartValueValidators.dependent<String>(
      dependsOn: dependsOn,
      validator: validator,
    );
  }

  /// Requires a non-empty string to equal another form [field].
  static SmartValidator matchesField(
    String field, {
    String message = 'Values do not match.',
  }) {
    return SmartValueValidators.matchesField<String>(field, message: message);
  }

  /// Requires this string when another [field] equals [equals].
  static SmartValidator requiredWhen({
    required String field,
    required Object? equals,
    String message = 'This field is required.',
  }) {
    return SmartValueValidators.requiredWhen<String>(
      field: field,
      equals: equals,
      message: message,
    );
  }

  /// Requires a non-null, non-empty string.
  static SmartValidator required({
    String message = 'This field is required.',
  }) => SmartValueValidators.required<String>(message: message);

  /// Requires a syntactically plausible email address when present.
  static SmartValidator email({
    String message = 'Enter a valid email address.',
  }) => SmartValueValidators.email(message: message);

  /// Requires a string to contain exactly [expected] characters.
  static SmartValidator length(int expected, {String? message}) {
    return SmartValueValidators.length<String>(expected, message: message);
  }

  /// Requires a string to contain at least [minimum] characters.
  static SmartValidator minLength(int minimum, {String? message}) {
    return SmartValueValidators.minLength<String>(minimum, message: message);
  }

  /// Requires a string to contain at most [maximum] characters.
  static SmartValidator maxLength(int maximum, {String? message}) {
    return SmartValueValidators.maxLength<String>(maximum, message: message);
  }

  /// Requires a string to match [pattern] when present.
  static SmartValidator pattern(
    Pattern pattern, {
    String message = 'Enter a value in the required format.',
  }) => SmartValueValidators.pattern(pattern, message: message);

  /// Requires a string to contain a finite number.
  static SmartValidator number({String message = 'Enter a valid number.'}) {
    return SmartValueValidators.number<String>(message: message);
  }

  /// Requires a numeric string greater than or equal to [minimum].
  static SmartValidator min(num minimum, {String? message}) {
    return SmartValueValidators.min<String>(minimum, message: message);
  }

  /// Requires a numeric string less than or equal to [maximum].
  static SmartValidator max(num maximum, {String? message}) {
    return SmartValueValidators.max<String>(maximum, message: message);
  }
}

/// Generic validator factories for typed dropdowns, dates, and custom fields.
abstract final class SmartValueValidators {
  /// Creates a validator with explicit [dependsOn] metadata.
  ///
  /// Every field read from [SmartValidationContext] should appear in
  /// [dependsOn] so source changes can automatically revalidate this field.
  static SmartValueValidator<T> dependent<T>({
    required Iterable<String> dependsOn,
    required SmartContextValidator<T> validator,
  }) {
    return createDependentValidator<T>(
      dependsOn: dependsOn,
      validator: validator,
    );
  }

  /// Requires a non-empty value to equal another form [field].
  ///
  /// Empty values are allowed; add [required] when confirmation is mandatory.
  static SmartValueValidator<T> matchesField<T>(
    String field, {
    String message = 'Values do not match.',
  }) {
    return dependent<T>(
      dependsOn: <String>[field],
      validator: (value, context) {
        if (_isEmpty(value)) {
          return null;
        }
        return value == context.values[field] ? null : message;
      },
    );
  }

  /// Requires this value when another [field] equals [equals].
  static SmartValueValidator<T> requiredWhen<T>({
    required String field,
    required Object? equals,
    String message = 'This field is required.',
  }) {
    return dependent<T>(
      dependsOn: <String>[field],
      validator: (value, context) {
        if (context.values[field] != equals) {
          return null;
        }
        return _isEmpty(value) ? message : null;
      },
    );
  }

  /// Requires a non-null, non-empty value.
  ///
  /// Strings containing only whitespace and empty iterables or maps are
  /// considered empty.
  static SmartValueValidator<T> required<T>({
    String message = 'This field is required.',
  }) {
    return (value) => _isEmpty(value) ? message : null;
  }

  /// Requires a syntactically plausible email address when a value is present.
  static SmartValidator email({
    String message = 'Enter a valid email address.',
  }) {
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return (value) {
      final normalized = value?.trim();
      if (normalized == null || normalized.isEmpty) {
        return null;
      }
      return pattern.hasMatch(normalized) ? null : message;
    };
  }

  /// Requires a string or collection to contain exactly [expected] items.
  static SmartValueValidator<T> length<T>(int expected, {String? message}) {
    _checkLength(expected, 'expected');
    final error = message ?? 'Must contain exactly $expected characters.';
    return (value) {
      if (_isEmpty(value)) {
        return null;
      }
      return _lengthOf(value) == expected ? null : error;
    };
  }

  /// Requires a string or collection to contain at least [minimum] items.
  static SmartValueValidator<T> minLength<T>(int minimum, {String? message}) {
    _checkLength(minimum, 'minimum');
    final error = message ?? 'Must contain at least $minimum characters.';
    return (value) {
      if (_isEmpty(value)) {
        return null;
      }
      final length = _lengthOf(value);
      return length != null && length >= minimum ? null : error;
    };
  }

  /// Requires a string or collection to contain at most [maximum] items.
  static SmartValueValidator<T> maxLength<T>(int maximum, {String? message}) {
    _checkLength(maximum, 'maximum');
    final error = message ?? 'Must contain at most $maximum characters.';
    return (value) {
      if (_isEmpty(value)) {
        return null;
      }
      final length = _lengthOf(value);
      return length != null && length <= maximum ? null : error;
    };
  }

  /// Requires a string to match [pattern] when a value is present.
  static SmartValidator pattern(
    Pattern pattern, {
    String message = 'Enter a value in the required format.',
  }) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return pattern.allMatches(value).isNotEmpty ? null : message;
    };
  }

  /// Requires a value to be a finite number.
  ///
  /// Numeric values and strings accepted by [num.tryParse] are supported.
  static SmartValueValidator<T> number<T>({
    String message = 'Enter a valid number.',
  }) {
    return (value) {
      if (_isEmpty(value)) {
        return null;
      }
      return _numberOf(value) == null ? message : null;
    };
  }

  /// Requires a numeric value greater than or equal to [minimum].
  static SmartValueValidator<T> min<T>(num minimum, {String? message}) {
    final error = message ?? 'Enter a value greater than or equal to $minimum.';
    return (value) {
      if (_isEmpty(value)) {
        return null;
      }
      final number = _numberOf(value);
      return number != null && number >= minimum ? null : error;
    };
  }

  /// Requires a numeric value less than or equal to [maximum].
  static SmartValueValidator<T> max<T>(num maximum, {String? message}) {
    final error = message ?? 'Enter a value less than or equal to $maximum.';
    return (value) {
      if (_isEmpty(value)) {
        return null;
      }
      final number = _numberOf(value);
      return number != null && number <= maximum ? null : error;
    };
  }

  static bool _isEmpty(Object? value) {
    return value == null ||
        value is String && value.trim().isEmpty ||
        value is Iterable<Object?> && value.isEmpty ||
        value is Map<Object?, Object?> && value.isEmpty;
  }

  static int? _lengthOf(Object? value) {
    return switch (value) {
      String value => value.length,
      Iterable<Object?> value => value.length,
      Map<Object?, Object?> value => value.length,
      _ => null,
    };
  }

  static num? _numberOf(Object? value) {
    final number = switch (value) {
      num value => value,
      String value => num.tryParse(value.trim()),
      _ => null,
    };
    return number != null && number.isFinite ? number : null;
  }

  static void _checkLength(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'Must not be negative.');
    }
  }
}
