import 'smart_form_result.dart';

/// Internal command surface implemented by a mounted smart form.
abstract interface class SmartFormControllerDelegate {
  /// Current values keyed by field name.
  Map<String, Object?> get values;

  /// Reads a typed field value.
  T? valueOf<T>(String name);

  /// Validates the form.
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  });

  /// Changes one field value.
  void setValue<T>(String name, T? value);

  /// Changes multiple field values atomically.
  void patchValue(Map<String, Object?> values);

  /// Resets every field.
  void reset();

  /// Clears every field error.
  void clearErrors();

  /// Applies one field error.
  void setFieldError(String name, String error);

  /// Applies multiple field errors.
  Future<void> setErrors(Map<String, String> errors, {bool scrollToFirstError});

  /// Reveals and focuses a field.
  Future<void> focusField(String name);

  /// Reveals a field without focusing it.
  Future<void> scrollToField(String name);
}

/// Imperative access to a mounted smart form.
final class SmartFormController {
  SmartFormControllerDelegate? _delegate;
  bool _disposed = false;

  /// Whether this controller is attached to a mounted form.
  bool get isAttached => _delegate != null;

  /// Returns an immutable snapshot of current registered field values.
  Map<String, Object?> get values => _requireDelegate().values;

  /// Returns field [name] as [T], or null when its value is null.
  T? valueOf<T>(String name) => _requireDelegate().valueOf<T>(name);

  /// Validates every enabled field and optionally navigates to the first error.
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) {
    return _requireDelegate().validate(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
  }

  /// Changes the value of field [name].
  void setValue<T>(String name, T? value) {
    _requireDelegate().setValue<T>(name, value);
  }

  /// Changes multiple field values after validating every supplied name.
  void patchValue(Map<String, Object?> values) {
    _requireDelegate().patchValue(values);
  }

  /// Restores every field to its initial value and clears its state.
  void reset() => _requireDelegate().reset();

  /// Clears all validation and server errors.
  void clearErrors() => _requireDelegate().clearErrors();

  /// Applies [error] to field [name].
  void setFieldError(String name, String error) {
    _requireDelegate().setFieldError(name, error);
  }

  /// Applies backend [errors] and optionally scrolls to the first one.
  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) {
    return _requireDelegate().setErrors(
      errors,
      scrollToFirstError: scrollToFirstError,
    );
  }

  /// Scrolls to and focuses field [name].
  Future<void> focusField(String name) {
    return _requireDelegate().focusField(name);
  }

  /// Scrolls field [name] into view without changing focus.
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

  /// Attaches this controller to a mounted form delegate.
  ///
  /// This is used by [SmartForm] and is not normally called by applications.
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

  /// Detaches [delegate] when it is the currently attached form.
  ///
  /// This is used by [SmartForm] and is not normally called by applications.
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
