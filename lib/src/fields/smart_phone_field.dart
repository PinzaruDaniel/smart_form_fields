import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_text_field.dart';

/// A phone input field without an opinionated international phone engine.
class SmartPhoneField extends StatefulWidget {
  /// Creates a phone field registered as [name].
  const SmartPhoneField({
    required this.name,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.countryCode,
    this.required = false,
    this.requiredMessage = 'This field is required.',
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// Unique form field name.
  final String name;

  /// Initial phone text used when no [controller] is supplied.
  final String? initialValue;

  /// Optional caller-owned text controller.
  final TextEditingController? controller;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Optional visual prefix, such as `+373`.
  final String? countryCode;

  /// Whether an empty value is invalid.
  final bool required;

  /// Message returned when [required] validation fails.
  final String requiredMessage;

  /// Additional synchronous validators for application-specific phone rules.
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

  /// Formatters applied to phone text edits.
  final List<TextInputFormatter>? inputFormatters;

  /// Action button displayed by the keyboard.
  final TextInputAction? textInputAction;

  /// Called whenever the phone value changes.
  final ValueChanged<String>? onChanged;

  /// Called when the platform submits the phone field.
  final ValueChanged<String>? onSubmitted;

  @override
  State<SmartPhoneField> createState() => _SmartPhoneFieldState();
}

class _SmartPhoneFieldState extends State<SmartPhoneField> {
  late List<SmartValidator> _validators;

  @override
  void initState() {
    super.initState();
    _rebuildValidators();
  }

  @override
  void didUpdateWidget(SmartPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.required != widget.required ||
        oldWidget.requiredMessage != widget.requiredMessage ||
        !identical(oldWidget.validators, widget.validators)) {
      _rebuildValidators();
    }
  }

  void _rebuildValidators() {
    _validators = <SmartValidator>[
      if (widget.required)
        SmartValidators.required(message: widget.requiredMessage),
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
      decoration: widget.decoration.copyWith(
        prefixText: widget.decoration.prefixText ?? widget.countryCode,
      ),
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
