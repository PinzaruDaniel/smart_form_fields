import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_text_field.dart';

/// A password field with optional required and minimum-length validation.
class SmartPasswordField extends StatefulWidget {
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
    this.autovalidateMode = AutovalidateMode.onUnfocus,
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

  final String name;
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool required;
  final String requiredMessage;
  final int? minLength;
  final String? minLengthMessage;
  final List<SmartValidator<String>> validators;
  final List<SmartAsyncValidator<String>> asyncValidators;
  final Duration? asyncValidationDebounce;
  final AutovalidateMode autovalidateMode;
  final SmartErrorAnimation? errorAnimation;
  final bool enabled;
  final InputDecoration decoration;
  final bool showVisibilityToggle;
  final bool initiallyObscured;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
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
