import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_text_field.dart';

/// A text field configured for email input and validation.
class SmartEmailField extends StatefulWidget {
  /// Creates an email field registered as [name].
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
    this.excludeFromDraft = false,
    super.key,
  });

  /// Unique form field name.
  final String name;

  /// Initial email used when no [controller] is supplied.
  final String? initialValue;

  /// Optional caller-owned text controller.
  final TextEditingController? controller;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Whether an empty value is invalid.
  final bool required;

  /// Message returned when [required] validation fails.
  final String requiredMessage;

  /// Message returned when email validation fails.
  final String invalidEmailMessage;

  /// Additional synchronous validators run after built-in validators.
  final List<SmartValidator> validators;

  /// Asynchronous validators run after synchronous validators pass.
  final List<SmartAsyncValidator<String>> asyncValidators;

  /// Debounce applied to automatic asynchronous validation.
  final Duration? asyncValidationDebounce;

  /// Field-level automatic validation override.
  final AutovalidateMode? autovalidateMode;

  /// Field-level error animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Whether the field accepts input and participates in validation.
  final bool enabled;

  /// Material input decoration.
  final InputDecoration decoration;

  /// Action button displayed by the keyboard.
  final TextInputAction? textInputAction;

  /// Called whenever the email value changes.
  final ValueChanged<String>? onChanged;

  /// Called when the platform submits the email field.
  final ValueChanged<String>? onSubmitted;

  /// Whether this field is omitted from persisted draft payloads.
  final bool excludeFromDraft;

  @override
  State<SmartEmailField> createState() => _SmartEmailFieldState();
}

class _SmartEmailFieldState extends State<SmartEmailField> {
  late List<SmartValidator> _validators;

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
    _validators = <SmartValidator>[
      if (widget.required)
        SmartValidators.required(message: widget.requiredMessage),
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
      excludeFromDraft: widget.excludeFromDraft,
    );
  }
}
