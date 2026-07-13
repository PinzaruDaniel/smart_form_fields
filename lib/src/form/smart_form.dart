import 'package:flutter/widgets.dart';

import 'smart_field_handle.dart';
import 'smart_field_registry.dart';
import 'smart_form_controller.dart';
import 'smart_form_result.dart';
import 'smart_form_scope.dart';

/// Coordinates the smart fields below it.
class SmartForm extends StatefulWidget {
  const SmartForm({
    required this.children,
    this.controller,
    this.scrollToFirstError = true,
    this.focusFirstError = true,
    this.mainAxisSize = MainAxisSize.min,
    super.key,
  });

  final List<Widget> children;
  final SmartFormController? controller;
  final bool scrollToFirstError;
  final bool focusFirstError;
  final MainAxisSize mainAxisSize;

  @override
  SmartFormState createState() => SmartFormState();
}

class SmartFormState extends State<SmartForm>
    implements SmartFormControllerDelegate, SmartFormRegistrar {
  final SmartFieldRegistry _registry = SmartFieldRegistry();

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(SmartForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    super.dispose();
  }

  @override
  Map<String, Object?> get values =>
      Map<String, Object?>.unmodifiable(_registry.values);

  @override
  T? valueOf<T>(String name) {
    final value = _fieldNamed(name).value;
    if (value == null) {
      return null;
    }
    if (value is! T) {
      throw StateError(
        'Field "$name" contains ${value.runtimeType}, not the requested type '
        '$T.',
      );
    }
    return value as T;
  }

  @override
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) async {
    final fields = _registry.fields;
    for (final field in fields) {
      if (field.enabled) {
        await field.validate();
      }
    }

    final errors = <String, String>{
      for (final field in fields)
        if (field.enabled && !field.isValid && field.errorText != null)
          field.name: field.errorText!,
    };
    final firstInvalidField = _registry.firstInvalidField;
    final shouldScroll = scrollToError ?? widget.scrollToFirstError;
    final shouldFocus = focusFirstError ?? widget.focusFirstError;

    if (firstInvalidField != null) {
      if (shouldScroll) {
        await firstInvalidField.scrollIntoView();
      }
      if (shouldFocus && mounted) {
        firstInvalidField.focus();
      }
    }

    return SmartFormResult(
      isValid: firstInvalidField == null,
      values: _registry.values,
      errors: errors,
    );
  }

  @override
  void setValue<T>(String name, T? value) {
    _fieldNamed(name).setValue(value);
  }

  @override
  void patchValue(Map<String, Object?> values) {
    final fields = <SmartFieldHandle<Object?>>[];
    for (final name in values.keys) {
      fields.add(_fieldNamed(name));
    }
    for (var index = 0; index < fields.length; index++) {
      fields[index].setValue(values.values.elementAt(index));
    }
  }

  @override
  void reset() => _registry.reset();

  @override
  void clearErrors() => _registry.clearErrors();

  @override
  void setFieldError(String name, String error) {
    _fieldNamed(name).setError(error);
  }

  @override
  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) async {
    final fields = <SmartFieldHandle<Object?>>[];
    for (final name in errors.keys) {
      fields.add(_fieldNamed(name));
    }
    for (var index = 0; index < fields.length; index++) {
      fields[index].setError(errors.values.elementAt(index));
    }
    if (scrollToFirstError) {
      await _registry.firstInvalidField?.scrollIntoView();
    }
  }

  @override
  Future<void> focusField(String name) async {
    _fieldNamed(name).focus();
  }

  @override
  Future<void> scrollToField(String name) {
    return _fieldNamed(name).scrollIntoView();
  }

  @override
  void registerField(
    SmartFieldHandle<Object?> field, {
    required int sectionOrder,
  }) {
    _registry.register(field, sectionOrder: sectionOrder);
  }

  @override
  void unregisterField(SmartFieldHandle<Object?> field) {
    _registry.unregister(field);
  }

  SmartFieldHandle<Object?> _fieldNamed(String name) {
    return _registry.fieldNamed(name) ??
        (throw ArgumentError.value(
          name,
          'name',
          'No field with this name is registered.',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return SmartFormScope(
      registrar: this,
      child: Column(
        mainAxisSize: widget.mainAxisSize,
        children: <Widget>[
          for (var index = 0; index < widget.children.length; index++)
            SmartFormOrderScope(
              key: widget.children[index].key == null
                  ? null
                  : ValueKey<Key>(widget.children[index].key!),
              order: index,
              child: widget.children[index],
            ),
        ],
      ),
    );
  }
}
