import 'package:flutter/widgets.dart';

/// The state exposed to a [SmartFormField] builder.
abstract interface class SmartFieldController<T> {
  /// Current field value.
  T? get value;

  /// Current validation or server error.
  String? get errorText;

  /// Whether this field accepts input and participates in validation.
  bool get enabled;

  /// Whether the field currently has no error.
  bool get isValid;

  /// Whether an asynchronous validator is currently running.
  bool get isValidating;

  /// Whether the value has changed since initialization or reset.
  bool get isDirty;

  /// Whether the user or application has interacted with this field.
  bool get isTouched;

  /// Focus node used by the field.
  FocusNode get focusNode;

  /// Updates the field to [value] and applies its validation timing policy.
  void didChange(T? value);

  /// Validates this field immediately and returns whether it is valid.
  Future<bool> validate();

  /// Restores the initial value and clears interaction and error state.
  void reset();

  /// Clears the current validation or server error.
  void clearError();
}
