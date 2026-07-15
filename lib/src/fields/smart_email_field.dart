import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_text_field.dart';

/// A text field configured for email input and validation.
class SmartEmailField extends StatefulWidget {
  const SmartEmailField({
    required this.name,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.required = false,
    this.requiredMessage = 'This field is required.',
    this.invalidEmailMessage = 'Enter a valid email address.',
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String name;
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool required;
  final String requiredMessage;
  final String invalidEmailMessage;
  final List<SmartValidator<String>> validators;
  final List<SmartAsyncValidator<String>> asyncValidators;
  final Duration? asyncValidationDebounce;
  final AutovalidateMode? autovalidateMode;
  final SmartErrorAnimation? errorAnimation;
  final bool enabled;
  final InputDecoration decoration;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SmartEmailField> createState() => _SmartEmailFieldState();
}

class _SmartEmailFieldState extends State<SmartEmailField> {
  late List<SmartValidator<String>> _validators;

  @override
  void initState() {
    super.initState();
    _rebuildValidators();
  }

  @override
  void didUpdateWidget(SmartEmailField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.required != widget.required ||
        oldWidget.requiredMessage != widget.requiredMessage ||
        oldWidget.invalidEmailMessage != widget.invalidEmailMessage ||
        !identical(oldWidget.validators, widget.validators)) {
      _rebuildValidators();
    }
  }

  void _rebuildValidators() {
    _validators = <SmartValidator<String>>[
      if (widget.required)
        SmartValidators.required<String>(message: widget.requiredMessage),
      SmartValidators.email(message: widget.invalidEmailMessage),
      ...widget.validators,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SmartTextField(
      name: widget.name,
      initialValue: widget.initialValue,
      controller: widget.controller,
      focusNode: widget.focusNode,
      validators: _validators,
      asyncValidators: widget.asyncValidators,
      asyncValidationDebounce: widget.asyncValidationDebounce,
      autovalidateMode: widget.autovalidateMode,
      errorAnimation: widget.errorAnimation,
      enabled: widget.enabled,
      decoration: widget.decoration,
      keyboardType: TextInputType.emailAddress,
      textInputAction: widget.textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
