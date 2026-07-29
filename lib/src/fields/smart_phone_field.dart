// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_field_view_item.dart';
import 'smart_text_field.dart';

/// Controls where [SmartPhoneField.countrySelector] is rendered.
enum SmartPhoneCountrySelectorLayout {
  /// Renders the selector within the Material input decoration.
  insideField,

  /// Renders the selector beside the input as a separate row child.
  separate,
}

/// The formatted and canonical representations of a submitted phone number.
final class SmartPhoneValue {
  /// Creates a parsed phone value.
  const SmartPhoneValue({required this.formatted, required this.e164});

  /// The human-readable value displayed by [SmartPhoneField].
  final String formatted;

  /// The canonical E.164 number, or `null` when parsing found no valid number.
  final String? e164;

  /// Whether parsing produced a canonical E.164 value.
  bool get isParsed => e164 != null;

  @override
  String toString() => e164 ?? formatted;
}

/// Parses displayed phone text into a submission-ready [SmartPhoneValue].
typedef SmartPhoneValueParser =
    FutureOr<SmartPhoneValue> Function(String formattedValue);

/// Immutable visual and behavioral configuration for a [SmartPhoneField].
final class SmartPhoneFieldViewItem extends SmartFieldViewItem {
  /// Creates a phone field item.
  const SmartPhoneFieldViewItem({
    required super.name,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.countryCode,
    this.countrySelector,
    this.countrySelectorLayout = SmartPhoneCountrySelectorLayout.insideField,
    this.countrySelectorSeparator,
    this.countrySelectorPadding = const EdgeInsets.symmetric(horizontal: 12),
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
    this.valueParser,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.excludeFromDraft = false,
  });

  /// Initial phone text.
  final String? initialValue;

  /// Optional caller-owned text controller.
  final TextEditingController? controller;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Optional visual calling-code prefix.
  final String? countryCode;

  /// Optional application-owned country selector.
  final Widget? countrySelector;

  /// Placement of [countrySelector].
  final SmartPhoneCountrySelectorLayout countrySelectorLayout;

  /// Optional separator after [countrySelector].
  final Widget? countrySelectorSeparator;

  /// Padding around an inside-field selector.
  final EdgeInsetsGeometry countrySelectorPadding;

  /// Whether an empty value is invalid.
  final bool required;

  /// Required-field validation message.
  final String requiredMessage;

  /// Additional synchronous validators.
  final List<SmartValidator> validators;

  /// Additional asynchronous validators.
  final List<SmartAsyncValidator<String>> asyncValidators;

  /// Automatic asynchronous-validation debounce.
  final Duration? asyncValidationDebounce;

  /// Field-level automatic validation override.
  final AutovalidateMode? autovalidateMode;

  /// Field-level error-animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Whether the field is enabled.
  final bool enabled;

  /// Material input decoration.
  final InputDecoration decoration;

  /// Formatters applied to phone text edits.
  final List<TextInputFormatter>? inputFormatters;

  /// Parser used to produce a submission-ready phone value.
  final SmartPhoneValueParser? valueParser;

  /// Action displayed by the keyboard.
  final TextInputAction? textInputAction;

  /// Called when the formatted phone text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the platform submits the phone field.
  final ValueChanged<String>? onSubmitted;

  /// Whether this field is omitted from persisted draft payloads.
  final bool excludeFromDraft;

  @override
  Widget build(BuildContext context) => SmartPhoneField(item: this);
}

/// A phone input that supports custom country selectors and phone formatters.
class SmartPhoneField extends StatefulWidget {
  /// Creates a phone field from direct parameters or an [item].
  ///
  /// Direct parameters override corresponding values from [item].
  const SmartPhoneField({
    this.item,
    String? name,
    String? initialValue,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? countryCode,
    Widget? countrySelector,
    SmartPhoneCountrySelectorLayout? countrySelectorLayout,
    Widget? countrySelectorSeparator,
    EdgeInsetsGeometry? countrySelectorPadding,
    bool? required,
    String? requiredMessage,
    List<SmartValidator>? validators,
    List<SmartAsyncValidator<String>>? asyncValidators,
    Duration? asyncValidationDebounce,
    AutovalidateMode? autovalidateMode,
    SmartErrorAnimation? errorAnimation,
    bool? enabled,
    InputDecoration? decoration,
    List<TextInputFormatter>? inputFormatters,
    SmartPhoneValueParser? valueParser,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool? excludeFromDraft,
    super.key,
  }) : assert(
         item != null || (name != null && name.length > 0),
         'Provide a SmartPhoneFieldViewItem or a non-empty name.',
       ),
       _name = name,
       _initialValue = initialValue,
       _controller = controller,
       _focusNode = focusNode,
       _countryCode = countryCode,
       _countrySelector = countrySelector,
       _countrySelectorLayout = countrySelectorLayout,
       _countrySelectorSeparator = countrySelectorSeparator,
       _countrySelectorPadding = countrySelectorPadding,
       _required = required,
       _requiredMessage = requiredMessage,
       _validators = validators,
       _asyncValidators = asyncValidators,
       _asyncValidationDebounce = asyncValidationDebounce,
       _autovalidateMode = autovalidateMode,
       _errorAnimation = errorAnimation,
       _enabled = enabled,
       _decoration = decoration,
       _inputFormatters = inputFormatters,
       _valueParser = valueParser,
       _textInputAction = textInputAction,
       _onChanged = onChanged,
       _onSubmitted = onSubmitted,
       _excludeFromDraft = excludeFromDraft;

  /// Optional immutable configuration used to create this field.
  final SmartPhoneFieldViewItem? item;

  final String? _name;

  /// Unique form field name.
  String get name => _name ?? item!.name;

  final String? _initialValue;

  /// Initial phone text used when no [controller] is supplied.
  String? get initialValue => _initialValue ?? item?.initialValue;

  final TextEditingController? _controller;

  /// Optional caller-owned text controller.
  TextEditingController? get controller => _controller ?? item?.controller;

  final FocusNode? _focusNode;

  /// Optional caller-owned focus node.
  FocusNode? get focusNode => _focusNode ?? item?.focusNode;

  final String? _countryCode;

  /// Optional visual prefix, such as `+373`.
  ///
  /// Ignored when [countrySelector] is supplied because the selector owns the
  /// visible calling code in that configuration.
  String? get countryCode => _countryCode ?? item?.countryCode;

  final Widget? _countrySelector;

  /// Optional application-owned country selector displayed before the input.
  ///
  /// This can be a button that opens a dropdown, dialog, or bottom sheet. The
  /// package deliberately does not prescribe how countries are selected, so
  /// callers can use localized country data from their preferred phone-number
  /// package.
  Widget? get countrySelector => _countrySelector ?? item?.countrySelector;

  final SmartPhoneCountrySelectorLayout? _countrySelectorLayout;

  /// Whether [countrySelector] is inside the input or beside it.
  SmartPhoneCountrySelectorLayout get countrySelectorLayout =>
      _countrySelectorLayout ??
      item?.countrySelectorLayout ??
      SmartPhoneCountrySelectorLayout.insideField;

  final Widget? _countrySelectorSeparator;

  /// Optional separator rendered between [countrySelector] and the input.
  ///
  /// A `VerticalDivider` is useful for [SmartPhoneCountrySelectorLayout.insideField],
  /// while a `SizedBox` can provide spacing for the separate layout.
  Widget? get countrySelectorSeparator =>
      _countrySelectorSeparator ?? item?.countrySelectorSeparator;

  final EdgeInsetsGeometry? _countrySelectorPadding;

  /// Padding around an inside-field [countrySelector].
  EdgeInsetsGeometry get countrySelectorPadding =>
      _countrySelectorPadding ??
      item?.countrySelectorPadding ??
      const EdgeInsets.symmetric(horizontal: 12);

  final bool? _required;

  /// Whether an empty value is invalid.
  bool get required => _required ?? item?.required ?? false;

  final String? _requiredMessage;

  /// Message returned when [required] validation fails.
  String get requiredMessage =>
      _requiredMessage ?? item?.requiredMessage ?? 'This field is required.';

  final List<SmartValidator>? _validators;

  /// Additional synchronous validators for application-specific phone rules.
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

  final bool? _enabled;

  /// Whether the field accepts input and participates in validation.
  bool get enabled => _enabled ?? item?.enabled ?? true;

  final InputDecoration? _decoration;

  /// Material input decoration.
  InputDecoration get decoration =>
      _decoration ?? item?.decoration ?? const InputDecoration();

  final List<TextInputFormatter>? _inputFormatters;

  /// Formatters applied to phone text edits.
  List<TextInputFormatter>? get inputFormatters =>
      _inputFormatters ?? item?.inputFormatters;

  final SmartPhoneValueParser? _valueParser;

  /// Optionally parses the formatted text for the validation result.
  ///
  /// When supplied, `SmartFormResult.values[name]` is a [SmartPhoneValue].
  /// Without a parser it remains the formatted `String` for compatibility.
  /// Live `SmartFormController.values` and validators always use the displayed
  /// string. The parser may be asynchronous, for example when backed by native
  /// libphonenumber APIs.
  SmartPhoneValueParser? get valueParser => _valueParser ?? item?.valueParser;

  final TextInputAction? _textInputAction;

  /// Action button displayed by the keyboard.
  TextInputAction? get textInputAction =>
      _textInputAction ?? item?.textInputAction;

  final ValueChanged<String>? _onChanged;

  /// Called whenever the phone value changes.
  ValueChanged<String>? get onChanged => _onChanged ?? item?.onChanged;

  final ValueChanged<String>? _onSubmitted;

  /// Called when the platform submits the phone field.
  ValueChanged<String>? get onSubmitted => _onSubmitted ?? item?.onSubmitted;

  final bool? _excludeFromDraft;

  /// Whether this field is omitted from persisted draft payloads.
  bool get excludeFromDraft =>
      _excludeFromDraft ?? item?.excludeFromDraft ?? false;

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

  Widget _buildCountrySelector({required bool insideField}) {
    final separator = widget.countrySelectorSeparator;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (insideField)
          Padding(
            padding: widget.countrySelectorPadding,
            child: widget.countrySelector,
          )
        else
          widget.countrySelector!,
        if (separator != null)
          SizedBox(height: insideField ? 32 : 56, child: separator),
      ],
    );
  }

  Widget _buildTextField({InputDecoration? decoration}) {
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
      decoration: decoration ?? widget.decoration,
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      resultValueTransformer: widget.valueParser == null
          ? null
          : (value) => widget.valueParser!(value ?? ''),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      excludeFromDraft: widget.excludeFromDraft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selector = widget.countrySelector;
    if (selector == null) {
      return _buildTextField(
        decoration: widget.decoration.copyWith(
          prefixText: widget.decoration.prefixText ?? widget.countryCode,
        ),
      );
    }

    if (widget.countrySelectorLayout ==
        SmartPhoneCountrySelectorLayout.separate) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCountrySelector(insideField: false),
          Expanded(child: _buildTextField()),
        ],
      );
    }

    final existingPrefixIcon = widget.decoration.prefixIcon;
    return _buildTextField(
      decoration: widget.decoration.copyWith(
        prefixText: null,
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildCountrySelector(insideField: true),
            ?existingPrefixIcon,
          ],
        ),
      ),
    );
  }
}
