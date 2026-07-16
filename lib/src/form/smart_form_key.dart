import 'package:flutter/widgets.dart';

import 'smart_form.dart';
import 'smart_form_result.dart';

/// A key that provides imperative access to a mounted [SmartForm].
final class SmartFormKey extends GlobalKey<SmartFormState> {
  /// Creates a unique key for one [SmartForm].
  // A const GlobalKey would be canonicalized and could accidentally be reused.
  // ignore: prefer_const_constructors_in_immutables
  SmartFormKey() : super.constructor();

  /// Returns an immutable snapshot of current registered field values.
  Map<String, Object?> get values => _state.values;

  /// Returns field [name] as [T], or null when its value is null.
  T? valueOf<T>(String name) => _state.valueOf<T>(name);

  /// Validates every enabled field and optionally navigates to the first error.
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) {
    return _state.validate(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
  }

  /// Changes the value of field [name].
  void setValue<T>(String name, T? value) {
    _state.setValue<T>(name, value);
  }

  /// Changes multiple field values after validating every supplied name.
  void patchValue(Map<String, Object?> values) => _state.patchValue(values);

  /// Restores every field to its initial value and clears its state.
  void reset() => _state.reset();

  /// Clears all validation and server errors.
  void clearErrors() => _state.clearErrors();

  /// Applies [error] to field [name].
  void setFieldError(String name, String error) {
    _state.setFieldError(name, error);
  }

  /// Applies backend [errors] and optionally scrolls to the first one.
  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) {
    return _state.setErrors(errors, scrollToFirstError: scrollToFirstError);
  }

  /// Scrolls to and focuses field [name].
  Future<void> focusField(String name) => _state.focusField(name);

  /// Scrolls field [name] into view without changing focus.
  Future<void> scrollToField(String name) => _state.scrollToField(name);

  SmartFormState get _state {
    return currentState ??
        (throw StateError(
          'SmartFormKey is not attached to a mounted SmartForm.',
        ));
  }
}
