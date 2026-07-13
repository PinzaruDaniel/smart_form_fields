import 'package:flutter/widgets.dart';

import 'smart_form.dart';
import 'smart_form_result.dart';

/// A key that provides imperative access to a mounted [SmartForm].
final class SmartFormKey extends GlobalKey<SmartFormState> {
  // A const GlobalKey would be canonicalized and could accidentally be reused.
  // ignore: prefer_const_constructors_in_immutables
  SmartFormKey() : super.constructor();

  Map<String, Object?> get values => _state.values;

  T? valueOf<T>(String name) => _state.valueOf<T>(name);

  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) {
    return _state.validate(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
  }

  void setValue<T>(String name, T? value) {
    _state.setValue<T>(name, value);
  }

  void patchValue(Map<String, Object?> values) => _state.patchValue(values);

  void reset() => _state.reset();

  void clearErrors() => _state.clearErrors();

  void setFieldError(String name, String error) {
    _state.setFieldError(name, error);
  }

  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) {
    return _state.setErrors(errors, scrollToFirstError: scrollToFirstError);
  }

  Future<void> focusField(String name) => _state.focusField(name);

  Future<void> scrollToField(String name) => _state.scrollToField(name);

  SmartFormState get _state {
    return currentState ??
        (throw StateError(
          'SmartFormKey is not attached to a mounted SmartForm.',
        ));
  }
}
