import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import 'smart_field_controller.dart';
import 'smart_form_field.dart';

/// A Material text field connected to the closest [SmartForm].
class SmartTextField extends StatefulWidget {
  /// Creates a Material text field registered as [name].
  const SmartTextField({
    required this.name,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
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
    this.resultValueTransformer,
    this.excludeFromDraft = false,
    super.key,
  }) : assert(
         controller == null || initialValue == null,
         'initialValue cannot be used with a TextEditingController.',
       );

  /// Unique form field name.
  final String name;

  /// Initial text used when no [controller] is supplied.
  final String? initialValue;

  /// Optional caller-owned text controller.
  final TextEditingController? controller;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Synchronous validators run in order.
  final List<SmartValidator> validators;

  /// Asynchronous validators run after synchronous validators pass.
  final List<SmartAsyncValidator<String>> asyncValidators;

  /// Debounce applied to automatic asynchronous validation.
  final Duration? asyncValidationDebounce;

  /// Field-level automatic validation override.
  final AutovalidateMode? autovalidateMode;

  /// Field-level error animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Whether the text field accepts input and participates in validation.
  final bool enabled;

  /// Material input decoration.
  final InputDecoration decoration;

  /// Keyboard configuration passed to `TextField`.
  final TextInputType? keyboardType;

  /// Action button displayed by the keyboard.
  final TextInputAction? textInputAction;

  /// Automatic capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Whether the entered text is obscured.
  final bool obscureText;

  /// Whether automatic correction is enabled.
  final bool autocorrect;

  /// Whether the platform may show input suggestions.
  final bool enableSuggestions;

  /// Formatters applied to text edits.
  final List<TextInputFormatter>? inputFormatters;

  /// Maximum number of displayed lines.
  final int? maxLines;

  /// Minimum number of displayed lines.
  final int? minLines;

  /// Called after a user or external controller edit updates the value.
  final ValueChanged<String>? onChanged;

  /// Called when the platform submits the text field.
  final ValueChanged<String>? onSubmitted;

  /// Optionally transforms the text captured in the validation result.
  final SmartResultValueTransformer<String>? resultValueTransformer;

  /// Whether this field is omitted from persisted draft payloads.
  final bool excludeFromDraft;

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
      asyncValidationDebounce: widget.asyncValidationDebounce,
      autovalidateMode: widget.autovalidateMode,
      errorAnimation: widget.errorAnimation,
      resultValueTransformer: widget.resultValueTransformer,
      excludeFromDraft: widget.excludeFromDraft,
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
