import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_text_field.dart';

/// A phone input field without an opinionated international phone engine.
class SmartPhoneField extends StatefulWidget {
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
    this.autovalidateMode = AutovalidateMode.onUnfocus,
    this.errorAnimation,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String name;
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? countryCode;
  final bool required;
  final String requiredMessage;
  final List<SmartValidator<String>> validators;
  final List<SmartAsyncValidator<String>> asyncValidators;
  final Duration? asyncValidationDebounce;
  final AutovalidateMode autovalidateMode;
  final SmartErrorAnimation? errorAnimation;
  final bool enabled;
  final InputDecoration decoration;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SmartPhoneField> createState() => _SmartPhoneFieldState();
}

class _SmartPhoneFieldState extends State<SmartPhoneField> {
  late List<SmartValidator<String>> _validators;

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
    _validators = <SmartValidator<String>>[
      if (widget.required)
        SmartValidators.required<String>(message: widget.requiredMessage),
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
