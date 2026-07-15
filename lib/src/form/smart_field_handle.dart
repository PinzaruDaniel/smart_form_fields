import 'dart:ui' show Offset;

/// Internal contract between a smart field and its containing form.
abstract interface class SmartFieldHandle<T> {
  String get name;

  T? get value;

  bool get enabled;

  bool get isValid;

  String? get errorText;

  Future<bool> validate({bool animateError = true});

  void setValue(T? value);

  void reset();

  void clearError();

  void setError(String error, {bool animateError = true});

  void animateError();

  void focus();

  bool containsGlobalPosition(Offset position);

  Future<void> scrollIntoView();
}
