import 'smart_form_result.dart';

abstract interface class SmartFormControllerDelegate {
  Map<String, Object?> get values;

  T? valueOf<T>(String name);

  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  });

  void setValue<T>(String name, T? value);

  void patchValue(Map<String, Object?> values);

  void reset();

  void clearErrors();

  void setFieldError(String name, String error);

  Future<void> setErrors(Map<String, String> errors, {bool scrollToFirstError});

  Future<void> focusField(String name);

  Future<void> scrollToField(String name);
}

/// Imperative access to a mounted smart form.
final class SmartFormController {
  SmartFormControllerDelegate? _delegate;
  bool _disposed = false;

  /// Whether this controller is attached to a mounted form.
  bool get isAttached => _delegate != null;

  Map<String, Object?> get values => _requireDelegate().values;

  T? valueOf<T>(String name) => _requireDelegate().valueOf<T>(name);

  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) {
    return _requireDelegate().validate(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
  }

  void setValue<T>(String name, T? value) {
    _requireDelegate().setValue<T>(name, value);
  }

  void patchValue(Map<String, Object?> values) {
    _requireDelegate().patchValue(values);
  }

  void reset() => _requireDelegate().reset();

  void clearErrors() => _requireDelegate().clearErrors();

  void setFieldError(String name, String error) {
    _requireDelegate().setFieldError(name, error);
  }

  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) {
    return _requireDelegate().setErrors(
      errors,
      scrollToFirstError: scrollToFirstError,
    );
  }

  Future<void> focusField(String name) {
    return _requireDelegate().focusField(name);
  }

  Future<void> scrollToField(String name) {
    return _requireDelegate().scrollToField(name);
  }

  /// Releases this controller.
  ///
  /// A form does not dispose a controller supplied by its caller.
  void dispose() {
    _disposed = true;
    _delegate = null;
  }

  void attach(SmartFormControllerDelegate delegate) {
    if (_disposed) {
      throw StateError('Cannot attach a disposed SmartFormController.');
    }
    if (_delegate != null && !identical(_delegate, delegate)) {
      throw StateError(
        'A SmartFormController cannot be attached to more than one SmartForm '
        'at a time.',
      );
    }
    _delegate = delegate;
  }

  void detach(SmartFormControllerDelegate delegate) {
    if (identical(_delegate, delegate)) {
      _delegate = null;
    }
  }

  SmartFormControllerDelegate _requireDelegate() {
    if (_disposed) {
      throw StateError('This SmartFormController has been disposed.');
    }
    return _delegate ??
        (throw StateError(
          'SmartFormController is not attached to a mounted SmartForm.',
        ));
  }
}
