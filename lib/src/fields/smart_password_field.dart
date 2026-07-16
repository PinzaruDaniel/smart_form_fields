import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_text_field.dart';

/// A password field with optional required and minimum-length validation.
class SmartPasswordField extends StatefulWidget {
  /// Creates a password field registered as [name].
  const SmartPasswordField({
    required this.name,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.required = false,
    this.requiredMessage = 'This field is required.',
    this.minLength = 8,
    this.minLengthMessage,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.showVisibilityToggle = true,
    this.initiallyObscured = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  }) : assert(minLength == null || minLength >= 0);

  /// Unique form field name.
  final String name;

  /// Initial password used when no [controller] is supplied.
  final String? initialValue;

  /// Optional caller-owned text controller.
  final TextEditingController? controller;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Whether an empty value is invalid.
  final bool required;

  /// Message returned when [required] validation fails.
  final String requiredMessage;

  /// Minimum password length, or null to disable length validation.
  final int? minLength;

  /// Optional message returned when [minLength] validation fails.
  final String? minLengthMessage;

  /// Additional synchronous validators run after built-in validators.
  final List<SmartValidator<String>> validators;

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

  /// Whether to display a password visibility button.
  final bool showVisibilityToggle;

  /// Whether text is obscured when the field is first built.
  final bool initiallyObscured;

  /// Action button displayed by the keyboard.
  final TextInputAction? textInputAction;

  /// Called whenever the password value changes.
  final ValueChanged<String>? onChanged;

  /// Called when the platform submits the password field.
  final ValueChanged<String>? onSubmitted;

  @override
  State<SmartPasswordField> createState() => _SmartPasswordFieldState();
}

class _SmartPasswordFieldState extends State<SmartPasswordField> {
  late bool _obscured;
  late List<SmartValidator<String>> _validators;

  @override
  void initState() {
    super.initState();
    _obscured = widget.initiallyObscured;
    _rebuildValidators();
  }

  @override
  void didUpdateWidget(SmartPasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.required != widget.required ||
        oldWidget.requiredMessage != widget.requiredMessage ||
        oldWidget.minLength != widget.minLength ||
        oldWidget.minLengthMessage != widget.minLengthMessage ||
        !identical(oldWidget.validators, widget.validators)) {
      _rebuildValidators();
    }
  }

  void _rebuildValidators() {
    _validators = <SmartValidator<String>>[
      if (widget.required)
        SmartValidators.required<String>(message: widget.requiredMessage),
      if (widget.minLength case final minimum?)
        SmartValidators.minLength<String>(
          minimum,
          message: widget.minLengthMessage,
        ),
      ...widget.validators,
    ];
  }

  void _toggleVisibility() {
    setState(() => _obscured = !_obscured);
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.showVisibilityToggle
        ? widget.decoration.copyWith(
            suffixIcon: IconButton(
              tooltip: _obscured ? 'Show password' : 'Hide password',
              onPressed: widget.enabled ? _toggleVisibility : null,
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          )
        : widget.decoration;

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
      decoration: decoration,
      textInputAction: widget.textInputAction,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
