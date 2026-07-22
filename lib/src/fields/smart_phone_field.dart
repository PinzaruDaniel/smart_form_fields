import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
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

/// A phone input that supports custom country selectors and phone formatters.
class SmartPhoneField extends StatefulWidget {
  /// Creates a phone field registered as [name].
  const SmartPhoneField({
    required this.name,
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
  ///
  /// Ignored when [countrySelector] is supplied because the selector owns the
  /// visible calling code in that configuration.
  final String? countryCode;

  /// Optional application-owned country selector displayed before the input.
  ///
  /// This can be a button that opens a dropdown, dialog, or bottom sheet. The
  /// package deliberately does not prescribe how countries are selected, so
  /// callers can use localized country data from their preferred phone-number
  /// package.
  final Widget? countrySelector;

  /// Whether [countrySelector] is inside the input or beside it.
  final SmartPhoneCountrySelectorLayout countrySelectorLayout;

  /// Optional separator rendered between [countrySelector] and the input.
  ///
  /// A `VerticalDivider` is useful for [SmartPhoneCountrySelectorLayout.insideField],
  /// while a `SizedBox` can provide spacing for the separate layout.
  final Widget? countrySelectorSeparator;

  /// Padding around an inside-field [countrySelector].
  final EdgeInsetsGeometry countrySelectorPadding;

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

  /// Optionally parses the formatted text for the validation result.
  ///
  /// When supplied, `SmartFormResult.values[name]` is a [SmartPhoneValue].
  /// Without a parser it remains the formatted `String` for compatibility.
  /// Live `SmartFormController.values` and validators always use the displayed
  /// string. The parser may be asynchronous, for example when backed by native
  /// libphonenumber APIs.
  final SmartPhoneValueParser? valueParser;

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
