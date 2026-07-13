import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import 'smart_field_controller.dart';
import 'smart_form_field.dart';

/// A Material text field connected to the closest [SmartForm].
class SmartTextField extends StatefulWidget {
  const SmartTextField({
    required this.name,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.validators = const [],
    this.asyncValidators = const [],
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    super.key,
  }) : assert(
         controller == null || initialValue == null,
         'initialValue cannot be used with a TextEditingController.',
       );

  final String name;
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final List<SmartValidator<String>> validators;
  final List<SmartAsyncValidator<String>> asyncValidators;
  final bool enabled;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  late TextEditingController _controller;
  SmartFieldController<String>? _field;
  bool _syncingController = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(SmartTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _controller.removeListener(_handleControllerChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller =
          widget.controller ??
          TextEditingController(
            text: _field?.value ?? widget.initialValue ?? '',
          );
      _controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_syncingController || _field?.value == _controller.text) {
      return;
    }
    _field?.didChange(_controller.text);
    widget.onChanged?.call(_controller.text);
  }

  void _syncController(String? value) {
    final text = value ?? '';
    if (_controller.text == text) {
      return;
    }
    _syncingController = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _syncingController = false;
  }

  @override
  Widget build(BuildContext context) {
    return SmartFormField<String>(
      name: widget.name,
      initialValue: _controller.text,
      validators: widget.validators,
      asyncValidators: widget.asyncValidators,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      builder: (context, field) {
        _field = field;
        _syncController(field.value);
        return TextField(
          controller: _controller,
          focusNode: field.focusNode,
          enabled: field.enabled,
          decoration: widget.decoration.copyWith(errorText: field.errorText),
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          onSubmitted: widget.onSubmitted,
        );
      },
    );
  }
}
