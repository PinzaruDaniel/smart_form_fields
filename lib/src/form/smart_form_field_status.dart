/// Immutable runtime state for one registered smart form field.
final class SmartFormFieldStatus {
  /// Creates a field-status snapshot.
  const SmartFormFieldStatus({
    required this.name,
    required this.value,
    required this.enabled,
    required this.excludeFromDraft,
    required this.isDirty,
    required this.isValid,
    required this.isValidating,
    required this.errorText,
  });

  /// Registered field name.
  final String name;

  /// Current live field value.
  final Object? value;

  /// Whether the field participates in validation.
  final bool enabled;

  /// Whether this field should be omitted from persisted drafts.
  final bool excludeFromDraft;

  /// Whether the field changed since its last reset.
  final bool isDirty;

  /// Whether the field currently has no validation error.
  final bool isValid;

  /// Whether asynchronous validation is currently running.
  final bool isValidating;

  /// Current validation or server error.
  final String? errorText;
}
