import 'package:flutter/widgets.dart';

/// The state exposed to a [SmartFormField] builder.
abstract interface class SmartFieldController<T> {
  T? get value;

  String? get errorText;

  bool get enabled;

  bool get isValid;

  bool get isValidating;

  bool get isDirty;

  bool get isTouched;

  FocusNode get focusNode;

  void didChange(T? value);

  Future<bool> validate();

  void reset();

  /// Clears the current validation or server error.
  void clearError();
}
