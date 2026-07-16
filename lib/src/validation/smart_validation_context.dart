import 'dart:collection';

/// Read-only form values available while a dependent validator runs.
final class SmartValidationContext {
  /// Creates an immutable validation snapshot from [values].
  SmartValidationContext(Map<String, Object?> values)
    : values = UnmodifiableMapView(Map<String, Object?>.of(values));

  /// Values keyed by registered field name at validation start.
  final Map<String, Object?> values;

  /// Returns field [name] as [T], or null when its value is null.
  ///
  /// Throws an [ArgumentError] for an unknown field and a [StateError] when a
  /// non-null value does not have the requested type.
  T? valueOf<T>(String name) {
    if (!values.containsKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'No field with this name exists in the validation context.',
      );
    }
    final value = values[name];
    if (value == null) {
      return null;
    }
    if (value is! T) {
      throw StateError(
        'Field "$name" contains ${value.runtimeType}, not the requested type '
        '$T.',
      );
    }
    return value as T;
  }
}

/// A synchronous validator that can read other form values through [context].
typedef SmartContextValidator<T> =
    String? Function(T? value, SmartValidationContext context);

/// An asynchronous validator that can read form values through [context].
typedef SmartContextAsyncValidator<T> =
    Future<String?> Function(T? value, SmartValidationContext context);
