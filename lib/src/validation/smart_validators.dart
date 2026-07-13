import 'smart_validator.dart';

/// Factories for commonly used synchronous validators.
///
/// Validators other than [required] allow `null` and blank strings. Add a
/// [required] validator first when a field must contain a value.
abstract final class SmartValidators {
  /// Requires a non-null, non-empty value.
  ///
  /// Strings containing only whitespace and empty iterables or maps are
  /// considered empty.
  static SmartValidator<T> required<T>({
    String message = 'This field is required.',
  }) {
    return (value) => _isEmpty(value) ? message : null;
  }

  /// Requires a syntactically plausible email address when a value is present.
  static SmartValidator<String> email({
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
  static SmartValidator<T> length<T>(int expected, {String? message}) {
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
  static SmartValidator<T> minLength<T>(int minimum, {String? message}) {
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
  static SmartValidator<T> maxLength<T>(int maximum, {String? message}) {
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
  static SmartValidator<String> pattern(
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
  static SmartValidator<T> number<T>({
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
  static SmartValidator<T> min<T>(num minimum, {String? message}) {
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
  static SmartValidator<T> max<T>(num maximum, {String? message}) {
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
