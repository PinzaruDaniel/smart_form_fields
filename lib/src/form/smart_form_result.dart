import 'dart:collection';

/// An immutable snapshot produced by validating a smart form.
final class SmartFormResult {
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
}
