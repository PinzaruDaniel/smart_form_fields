import 'dart:collection';

/// An immutable snapshot produced by validating a smart form.
final class SmartFormResult {
  /// Creates an immutable validation result from the supplied snapshots.
  SmartFormResult({
    required this.isValid,
    required Map<String, Object?> values,
    required Map<String, String> errors,
  }) : values = UnmodifiableMapView(Map<String, Object?>.of(values)),
       errors = UnmodifiableMapView(Map<String, String>.of(errors));

  /// Whether every enabled field passed validation.
  final bool isValid;

  /// Values captured when validation completed.
  final Map<String, Object?> values;

  /// Validation errors keyed by field name.
  final Map<String, String> errors;

  /// Whether a value for [name] exists in this result.
  bool contains(String name) => values.containsKey(name);

  /// Returns field [name] as [T], or null when its value is null.
  ///
  /// Throws an [ArgumentError] for an unknown field and a [StateError] when a
  /// non-null value does not have the requested type.
  T? valueOf<T>(String name) {
    if (!values.containsKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'No field with this name exists in the form result.',
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

  /// Returns the text value for [name], or null when the value is null.
  ///
  /// This is intended for text-based fields. It throws a [StateError] when the
  /// value exists but is not a [String], so parsed values such as phone objects
  /// stay explicit.
  String? maybeText(String name) => valueOf<String>(name);

  /// Returns the text value for [name], or [fallback] when the value is null.
  String text(String name, {String fallback = ''}) =>
      maybeText(name) ?? fallback;
}
