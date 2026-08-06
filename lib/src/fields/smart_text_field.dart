// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import 'smart_field_view_item.dart';
import 'smart_field_controller.dart';
import 'smart_form_field.dart';

/// Immutable visual and behavioral configuration for a [SmartTextField].
///
/// The item owns a [TextEditingController] when one is not supplied, allowing
/// callers to read [text] directly from the item.
final class SmartTextFieldViewItem extends SmartFieldViewItem {
  /// Creates a text field item.
  SmartTextFieldViewItem({
    required super.name,
    this.initialValue,
    TextEditingController? controller,
    this.focusNode,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
    this.errorAnimationBuilder,
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
  }) : assert(
         controller == null || initialValue == null,
         'initialValue cannot be used with a TextEditingController.',
       ),
       _controller =
           controller ?? TextEditingController(text: initialValue ?? ''),
       _ownsController = controller == null;

  /// Initial text used when no [controller] is supplied.
  final String? initialValue;

  final TextEditingController _controller;
  final bool _ownsController;

  /// Text controller used by the built field.
  TextEditingController get controller => _controller;

  /// Current text in [controller].
  @override
  String get text => _controller.text;

  /// Current text as nullable value.
  @override
  String? get maybeText => _controller.text;

  /// Updates [controller] text.
  set text(String value) => _controller.text = value;

  /// Current field value.
  @override
  Object? get value => _controller.text;

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

  /// Field-level custom error animation override.
  final SmartErrorAnimationBuilder? errorAnimationBuilder;

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

  /// Disposes the internally owned controller.
  ///
  /// Calling this is unnecessary when a caller-owned [controller] was supplied.
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => SmartTextField(item: this);
}

/// A Material text field connected to the closest [SmartForm].
class SmartTextField extends StatefulWidget {
  /// Creates a Material text field from direct parameters or an [item].
  ///
  /// Direct parameters override corresponding values from [item].
  const SmartTextField({
    this.item,
    String? name,
    String? initialValue,
    TextEditingController? controller,
    FocusNode? focusNode,
    List<SmartValidator>? validators,
    List<SmartAsyncValidator<String>>? asyncValidators,
    Duration? asyncValidationDebounce,
    AutovalidateMode? autovalidateMode,
    SmartErrorAnimation? errorAnimation,
    SmartErrorAnimationBuilder? errorAnimationBuilder,
    bool? enabled,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization? textCapitalization,
    bool? obscureText,
    bool? autocorrect,
    bool? enableSuggestions,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines,
    int? minLines,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    SmartResultValueTransformer<String>? resultValueTransformer,
    bool? excludeFromDraft,
    super.key,
  }) : assert(
         controller == null || initialValue == null,
         'initialValue cannot be used with a TextEditingController.',
       ),
       assert(
         item != null || (name != null && name.length > 0),
         'Provide a SmartTextFieldViewItem or a non-empty name.',
       ),
       _name = name,
       _initialValue = initialValue,
       _controller = controller,
       _focusNode = focusNode,
       _validators = validators,
       _asyncValidators = asyncValidators,
       _asyncValidationDebounce = asyncValidationDebounce,
       _autovalidateMode = autovalidateMode,
       _errorAnimation = errorAnimation,
       _errorAnimationBuilder = errorAnimationBuilder,
       _enabled = enabled,
       _decoration = decoration,
       _keyboardType = keyboardType,
       _textInputAction = textInputAction,
       _textCapitalization = textCapitalization,
       _obscureText = obscureText,
       _autocorrect = autocorrect,
       _enableSuggestions = enableSuggestions,
       _inputFormatters = inputFormatters,
       _maxLines = maxLines,
       _minLines = minLines,
       _onChanged = onChanged,
       _onSubmitted = onSubmitted,
       _resultValueTransformer = resultValueTransformer,
       _excludeFromDraft = excludeFromDraft;

  /// Optional immutable configuration used to create this field.
  final SmartTextFieldViewItem? item;

  final String? _name;

  /// Unique form field name.
  String get name => _name ?? item!.name;

  final String? _initialValue;

  /// Initial text used when no [controller] is supplied.
  String? get initialValue => _initialValue ?? item?.initialValue;

  final TextEditingController? _controller;

  /// Optional caller-owned text controller.
  TextEditingController? get controller => _controller ?? item?.controller;

  final FocusNode? _focusNode;

  /// Optional caller-owned focus node.
  FocusNode? get focusNode => _focusNode ?? item?.focusNode;

  final List<SmartValidator>? _validators;

  /// Synchronous validators run in order.
  List<SmartValidator> get validators =>
      _validators ?? item?.validators ?? const [];

  final List<SmartAsyncValidator<String>>? _asyncValidators;

  /// Asynchronous validators run after synchronous validators pass.
  List<SmartAsyncValidator<String>> get asyncValidators =>
      _asyncValidators ?? item?.asyncValidators ?? const [];

  final Duration? _asyncValidationDebounce;

  /// Debounce applied to automatic asynchronous validation.
  Duration? get asyncValidationDebounce =>
      _asyncValidationDebounce ?? item?.asyncValidationDebounce;

  final AutovalidateMode? _autovalidateMode;

  /// Field-level automatic validation override.
  AutovalidateMode? get autovalidateMode =>
      _autovalidateMode ?? item?.autovalidateMode;

  final SmartErrorAnimation? _errorAnimation;

  /// Field-level error animation override.
  SmartErrorAnimation? get errorAnimation =>
      _errorAnimation ?? item?.errorAnimation;

  final SmartErrorAnimationBuilder? _errorAnimationBuilder;

  /// Field-level custom error animation override.
  SmartErrorAnimationBuilder? get errorAnimationBuilder =>
      _errorAnimationBuilder ?? item?.errorAnimationBuilder;

  final bool? _enabled;

  /// Whether the text field accepts input and participates in validation.
  bool get enabled => _enabled ?? item?.enabled ?? true;

  final InputDecoration? _decoration;

  /// Material input decoration.
  InputDecoration get decoration =>
      _decoration ?? item?.decoration ?? const InputDecoration();

  final TextInputType? _keyboardType;

  /// Keyboard configuration passed to `TextField`.
  TextInputType? get keyboardType => _keyboardType ?? item?.keyboardType;

  final TextInputAction? _textInputAction;

  /// Action button displayed by the keyboard.
  TextInputAction? get textInputAction =>
      _textInputAction ?? item?.textInputAction;

  final TextCapitalization? _textCapitalization;

  /// Automatic capitalization behavior.
  TextCapitalization get textCapitalization =>
      _textCapitalization ??
      item?.textCapitalization ??
      TextCapitalization.none;

  final bool? _obscureText;

  /// Whether the entered text is obscured.
  bool get obscureText => _obscureText ?? item?.obscureText ?? false;

  final bool? _autocorrect;

  /// Whether automatic correction is enabled.
  bool get autocorrect => _autocorrect ?? item?.autocorrect ?? true;

  final bool? _enableSuggestions;

  /// Whether the platform may show input suggestions.
  bool get enableSuggestions =>
      _enableSuggestions ?? item?.enableSuggestions ?? true;

  final List<TextInputFormatter>? _inputFormatters;

  /// Formatters applied to text edits.
  List<TextInputFormatter>? get inputFormatters =>
      _inputFormatters ?? item?.inputFormatters;

  final int? _maxLines;

  /// Maximum number of displayed lines.
  int? get maxLines => _maxLines ?? item?.maxLines ?? 1;

  final int? _minLines;

  /// Minimum number of displayed lines.
  int? get minLines => _minLines ?? item?.minLines;

  final ValueChanged<String>? _onChanged;

  /// Called after a user or external controller edit updates the value.
  ValueChanged<String>? get onChanged => _onChanged ?? item?.onChanged;

  final ValueChanged<String>? _onSubmitted;

  /// Called when the platform submits the text field.
  ValueChanged<String>? get onSubmitted => _onSubmitted ?? item?.onSubmitted;

  final SmartResultValueTransformer<String>? _resultValueTransformer;

  /// Optionally transforms the text captured in the validation result.
  SmartResultValueTransformer<String>? get resultValueTransformer =>
      _resultValueTransformer ?? item?.resultValueTransformer;

  final bool? _excludeFromDraft;

  /// Whether this field is omitted from persisted draft payloads.
  bool get excludeFromDraft =>
      _excludeFromDraft ?? item?.excludeFromDraft ?? false;

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
      errorAnimationBuilder: widget.errorAnimationBuilder,
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
