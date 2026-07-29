import 'package:flutter/foundation.dart';

import 'dart:async';

import 'smart_api_errors.dart';
import 'smart_form_field_status.dart';
import 'smart_form_result.dart';

/// Called after a form validates successfully during submission.
typedef SmartFormSubmitCallback =
    FutureOr<void> Function(Map<String, Object?> values);

/// Internal command surface implemented by a mounted smart form.
abstract interface class SmartFormControllerDelegate {
  /// Current values keyed by field name.
  Map<String, Object?> get values;

  /// Current state keyed by field name.
  Map<String, SmartFormFieldStatus> get fieldStatuses;

  /// Registers an observer for form value and status changes.
  void addFormListener(VoidCallback listener);

  /// Removes a previously registered observer.
  void removeFormListener(VoidCallback listener);

  /// Reads a typed field value.
  T? valueOf<T>(String name);

  /// Validates the form.
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  });

  /// Validates the form and runs its submit callback when valid.
  Future<SmartFormResult> submit({bool? scrollToError, bool? focusFirstError});

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

  /// Parses and applies field errors from a complete API response.
  Future<SmartApiErrorResult> setErrorsFromResponse(
    Object? response, {
    SmartApiErrorExtractor? extractor,
    Map<String, String> fieldAliases,
    String messageSeparator,
    bool clearExistingErrors,
    bool scrollToFirstError,
  });

  /// Reveals and focuses a field.
  Future<void> focusField(String name);

  /// Reveals a field without focusing it.
  Future<void> scrollToField(String name);
}

/// Imperative access to a mounted smart form.
final class SmartFormController extends ChangeNotifier {
  SmartFormControllerDelegate? _delegate;
  bool _disposed = false;
  bool _isSubmitting = false;
  Future<SmartFormResult>? _activeSubmission;
  SmartFormResult? _lastSubmitResult;
  Object? _submissionError;

  /// Whether this controller is attached to a mounted form.
  bool get isAttached => _delegate != null;

  /// Whether a submit call is currently validating or running `onSubmit`.
  bool get isSubmitting => _isSubmitting;

  /// Last validation result produced by [submit], when available.
  SmartFormResult? get lastSubmitResult => _lastSubmitResult;

  /// Last error thrown by the form submit callback.
  Object? get submissionError => _submissionError;

  /// Returns an immutable snapshot of current registered field values.
  Map<String, Object?> get values => _requireDelegate().values;

  /// Returns immutable runtime state for every registered field.
  Map<String, SmartFormFieldStatus> get fieldStatuses =>
      _requireDelegate().fieldStatuses;

  /// Names of fields changed since their last reset.
  Set<String> get dirtyFields => <String>{
    for (final status in fieldStatuses.values)
      if (status.isDirty) status.name,
  };

  /// Whether at least one field has changed since reset.
  bool get isDirty => dirtyFields.isNotEmpty;

  /// Names of fields currently running asynchronous validation.
  Set<String> get validatingFields => <String>{
    for (final status in fieldStatuses.values)
      if (status.isValidating) status.name,
  };

  /// Whether any field is currently running asynchronous validation.
  bool get isValidating => validatingFields.isNotEmpty;

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

  /// Validates the form, prevents duplicate concurrent submissions, and runs
  /// `SmartForm.onSubmit` when the form is valid.
  Future<SmartFormResult> submit({bool? scrollToError, bool? focusFirstError}) {
    final active = _activeSubmission;
    if (active != null) {
      return active;
    }
    final submission = _submit(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
    _activeSubmission = submission;
    return submission;
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

  /// Parses a complete decoded API [response] and applies matching errors.
  ///
  /// Common nested maps and error arrays are supported automatically. Use
  /// [fieldAliases] to map backend names to form names, or [extractor] for an
  /// application-specific response shape. Unmapped and general messages are
  /// returned to the caller.
  Future<SmartApiErrorResult> setErrorsFromResponse(
    Object? response, {
    SmartApiErrorExtractor? extractor,
    Map<String, String> fieldAliases = const {},
    String messageSeparator = '\n',
    bool clearExistingErrors = false,
    bool scrollToFirstError = false,
  }) {
    return _requireDelegate().setErrorsFromResponse(
      response,
      extractor: extractor,
      fieldAliases: fieldAliases,
      messageSeparator: messageSeparator,
      clearExistingErrors: clearExistingErrors,
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
  @override
  void dispose() {
    _delegate?.removeFormListener(_handleFormChanged);
    _disposed = true;
    _delegate = null;
    super.dispose();
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
    delegate.addFormListener(_handleFormChanged);
  }

  /// Detaches [delegate] when it is the currently attached form.
  ///
  /// This is used by [SmartForm] and is not normally called by applications.
  void detach(SmartFormControllerDelegate delegate) {
    if (identical(_delegate, delegate)) {
      delegate.removeFormListener(_handleFormChanged);
      _delegate = null;
    }
  }

  void _handleFormChanged() => notifyListeners();

  Future<SmartFormResult> _submit({
    bool? scrollToError,
    bool? focusFirstError,
  }) async {
    _isSubmitting = true;
    _submissionError = null;
    notifyListeners();
    try {
      final result = await _requireDelegate().submit(
        scrollToError: scrollToError,
        focusFirstError: focusFirstError,
      );
      _lastSubmitResult = result;
      return result;
    } catch (error) {
      _submissionError = error;
      rethrow;
    } finally {
      _isSubmitting = false;
      _activeSubmission = null;
      notifyListeners();
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
