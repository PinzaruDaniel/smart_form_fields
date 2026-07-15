import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../fields/smart_date_field.dart';
import '../fields/smart_dropdown_field.dart';
import '../fields/smart_email_field.dart';
import '../fields/smart_password_field.dart';
import '../fields/smart_phone_field.dart';
import '../fields/smart_text_field.dart';
import '../form/smart_form.dart';
import '../form/smart_form_controller.dart';
import '../form/smart_form_key.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_form_schema.dart';

/// Builds an application-specific JSON field type.
typedef SmartJsonFieldBuilder =
    Widget Function(
      BuildContext context,
      SmartJsonFieldDefinition definition,
      List<SmartValidator<Object?>> validators,
      List<SmartAsyncValidator<Object?>> asyncValidators,
    );

/// Converts application-specific JSON validator configuration into code.
typedef SmartJsonValidatorBuilder =
    SmartValidator<Object?> Function(SmartJsonValidatorDefinition definition);

/// Builds a [SmartForm] from an API-provided JSON schema.
class SmartJsonForm extends StatelessWidget {
  const SmartJsonForm({
    required this.schema,
    this.controller,
    this.formKey,
    this.customFieldBuilders = const {},
    this.customValidatorBuilders = const {},
    this.asyncValidators = const {},
    this.spacing = 16,
    this.scrollToFirstError,
    this.focusFirstError,
    this.errorAnimation,
    this.dismissKeyboardOnTapOutside = true,
    this.unfocusOnKeyboardDismiss = true,
    this.onKeyboardVisibilityChanged,
    this.autovalidateMode = AutovalidateMode.onUnfocus,
    super.key,
  });

  factory SmartJsonForm.fromJson({
    required Map<String, Object?> json,
    SmartFormController? controller,
    SmartFormKey? formKey,
    Map<String, SmartJsonFieldBuilder> customFieldBuilders = const {},
    Map<String, SmartJsonValidatorBuilder> customValidatorBuilders = const {},
    Map<String, SmartAsyncValidator<Object?>> asyncValidators = const {},
    double spacing = 16,
    bool? scrollToFirstError,
    bool? focusFirstError,
    SmartErrorAnimation? errorAnimation,
    bool dismissKeyboardOnTapOutside = true,
    bool unfocusOnKeyboardDismiss = true,
    ValueChanged<bool>? onKeyboardVisibilityChanged,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUnfocus,
    Key? key,
  }) {
    return SmartJsonForm(
      key: key,
      schema: SmartFormSchema.fromJson(json),
      controller: controller,
      formKey: formKey,
      customFieldBuilders: customFieldBuilders,
      customValidatorBuilders: customValidatorBuilders,
      asyncValidators: asyncValidators,
      spacing: spacing,
      scrollToFirstError: scrollToFirstError,
      focusFirstError: focusFirstError,
      errorAnimation: errorAnimation,
      dismissKeyboardOnTapOutside: dismissKeyboardOnTapOutside,
      unfocusOnKeyboardDismiss: unfocusOnKeyboardDismiss,
      onKeyboardVisibilityChanged: onKeyboardVisibilityChanged,
      autovalidateMode: autovalidateMode,
    );
  }

  final SmartFormSchema schema;
  final SmartFormController? controller;
  final SmartFormKey? formKey;
  final Map<String, SmartJsonFieldBuilder> customFieldBuilders;
  final Map<String, SmartJsonValidatorBuilder> customValidatorBuilders;
  final Map<String, SmartAsyncValidator<Object?>> asyncValidators;
  final double spacing;
  final bool? scrollToFirstError;
  final bool? focusFirstError;
  final SmartErrorAnimation? errorAnimation;
  final bool dismissKeyboardOnTapOutside;
  final bool unfocusOnKeyboardDismiss;
  final ValueChanged<bool>? onKeyboardVisibilityChanged;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      for (final definition in schema.fields) _buildField(context, definition),
    ];
    return SmartForm(
      key: formKey,
      controller: controller,
      scrollToFirstError: scrollToFirstError ?? schema.scrollToFirstError,
      focusFirstError: focusFirstError ?? schema.focusFirstError,
      errorAnimation: errorAnimation ?? schema.errorAnimation,
      dismissKeyboardOnTapOutside: dismissKeyboardOnTapOutside,
      unfocusOnKeyboardDismiss: unfocusOnKeyboardDismiss,
      onKeyboardVisibilityChanged: onKeyboardVisibilityChanged,
      autovalidateMode: autovalidateMode,
      children: <Widget>[
        for (var index = 0; index < fields.length; index++) ...<Widget>[
          if (index > 0 && spacing > 0) SizedBox(height: spacing),
          fields[index],
        ],
      ],
    );
  }

  Widget _buildField(
    BuildContext context,
    SmartJsonFieldDefinition definition,
  ) {
    final validators = _validatorsFor(definition);
    final asyncValidators = _asyncValidatorsFor(definition);
    final decoration = InputDecoration(
      labelText: definition.stringValue('label_text'),
      hintText: definition.stringValue('hint_text'),
      helperText: definition.stringValue('helper_text'),
    );
    final enabled = definition.boolValue('enabled', fallback: true);
    final required = definition.boolValue('required', fallback: false);
    final requiredMessage =
        definition.stringValue('required_message') ?? 'This field is required.';
    final autovalidateMode = _autovalidateMode(definition);

    switch (definition.type) {
      case 'text':
        return SmartTextField(
          name: definition.name,
          initialValue: definition.stringValue('initial_value'),
          enabled: enabled,
          decoration: decoration,
          maxLines: definition.intValue('max_lines') ?? 1,
          autovalidateMode: autovalidateMode,
          validators: <SmartValidator<String>>[
            if (required)
              SmartValidators.required<String>(message: requiredMessage),
            ..._adaptValidators<String>(validators),
          ],
          asyncValidators: _adaptAsyncValidators<String>(asyncValidators),
        );
      case 'email':
        return SmartEmailField(
          name: definition.name,
          initialValue: definition.stringValue('initial_value'),
          enabled: enabled,
          required: required,
          requiredMessage: requiredMessage,
          invalidEmailMessage:
              definition.stringValue('invalid_email_message') ??
              'Enter a valid email address.',
          decoration: decoration,
          autovalidateMode: autovalidateMode,
          validators: _adaptValidators<String>(validators),
          asyncValidators: _adaptAsyncValidators<String>(asyncValidators),
        );
      case 'phone':
        return SmartPhoneField(
          name: definition.name,
          initialValue: definition.stringValue('initial_value'),
          countryCode: definition.stringValue('country_code'),
          enabled: enabled,
          required: required,
          requiredMessage: requiredMessage,
          decoration: decoration,
          autovalidateMode: autovalidateMode,
          validators: _adaptValidators<String>(validators),
          asyncValidators: _adaptAsyncValidators<String>(asyncValidators),
        );
      case 'password':
        return SmartPasswordField(
          name: definition.name,
          initialValue: definition.stringValue('initial_value'),
          enabled: enabled,
          required: required,
          requiredMessage: requiredMessage,
          minLength: definition.intValue('min_length'),
          minLengthMessage: definition.stringValue('min_length_message'),
          showVisibilityToggle: definition.boolValue(
            'show_visibility_toggle',
            fallback: true,
          ),
          decoration: decoration,
          autovalidateMode: autovalidateMode,
          validators: _adaptValidators<String>(validators),
          asyncValidators: _adaptAsyncValidators<String>(asyncValidators),
        );
      case 'date':
        return SmartDateField(
          name: definition.name,
          initialValue: _dateValue(definition, 'initial_value'),
          firstDate: _dateValue(definition, 'first_date') ?? DateTime(1900),
          lastDate: _dateValue(definition, 'last_date') ?? DateTime(2100),
          enabled: enabled,
          required: required,
          requiredMessage: requiredMessage,
          decoration: decoration,
          autovalidateMode: autovalidateMode,
          validators: _adaptValidators<DateTime>(validators),
          asyncValidators: _adaptAsyncValidators<DateTime>(asyncValidators),
        );
      case 'dropdown':
        final options = <_JsonOption>[
          for (final option in definition.listValue('options'))
            _JsonOption.fromJson(option, definition.name),
        ];
        return SmartDropdownField<Object?>(
          name: definition.name,
          items: <Object?>[for (final option in options) option.value],
          itemLabelBuilder: (value) =>
              options.firstWhere((option) => option.value == value).label,
          initialValue: definition.properties['initial_value'],
          enabled: enabled,
          required: required,
          requiredMessage: requiredMessage,
          decoration: decoration,
          autovalidateMode: autovalidateMode,
          validators: validators,
          asyncValidators: asyncValidators,
        );
      default:
        final builder = customFieldBuilders[definition.type];
        if (builder == null) {
          throw FlutterError(
            'No JSON field builder is registered for type '
            '"${definition.type}".',
          );
        }
        return builder(context, definition, <SmartValidator<Object?>>[
          if (required)
            SmartValidators.required<Object?>(message: requiredMessage),
          ...validators,
        ], asyncValidators);
    }
  }

  List<SmartValidator<Object?>> _validatorsFor(SmartJsonFieldDefinition field) {
    return <SmartValidator<Object?>>[
      for (final definition in field.validators)
        _validatorFromDefinition(definition),
    ];
  }

  SmartValidator<Object?> _validatorFromDefinition(
    SmartJsonValidatorDefinition definition,
  ) {
    switch (definition.type) {
      case 'required':
        return SmartValidators.required<Object?>(
          message: definition.message ?? 'This field is required.',
        );
      case 'email':
        final validator = SmartValidators.email(
          message: definition.message ?? 'Enter a valid email address.',
        );
        return (value) => validator(value as String?);
      case 'length':
        return SmartValidators.length<Object?>(
          definition.requireInt('value'),
          message: definition.message,
        );
      case 'min_length':
      case 'minLength':
        return SmartValidators.minLength<Object?>(
          definition.requireInt('value'),
          message: definition.message,
        );
      case 'max_length':
      case 'maxLength':
        return SmartValidators.maxLength<Object?>(
          definition.requireInt('value'),
          message: definition.message,
        );
      case 'pattern':
        final validator = SmartValidators.pattern(
          RegExp(definition.requireString('pattern')),
          message:
              definition.message ?? 'Enter a value in the required format.',
        );
        return (value) => validator(value as String?);
      case 'number':
        return SmartValidators.number<Object?>(
          message: definition.message ?? 'Enter a valid number.',
        );
      case 'min':
        return SmartValidators.min<Object?>(
          definition.requireNum('value'),
          message: definition.message,
        );
      case 'max':
        return SmartValidators.max<Object?>(
          definition.requireNum('value'),
          message: definition.message,
        );
      default:
        final builder = customValidatorBuilders[definition.type];
        if (builder == null) {
          throw FlutterError(
            'No JSON validator builder is registered for type '
            '"${definition.type}".',
          );
        }
        return builder(definition);
    }
  }

  List<SmartAsyncValidator<Object?>> _asyncValidatorsFor(
    SmartJsonFieldDefinition field,
  ) {
    return <SmartAsyncValidator<Object?>>[
      for (final name in field.asyncValidators)
        asyncValidators[name] ??
            (throw FlutterError(
              'No async validator is registered for "$name".',
            )),
    ];
  }

  AutovalidateMode? _autovalidateMode(SmartJsonFieldDefinition field) {
    final value = field.stringValue('autovalidate_mode');
    if (value == null) {
      return null;
    }
    final mode = switch (value) {
      'disabled' => AutovalidateMode.disabled,
      'always' => AutovalidateMode.always,
      'on_user_interaction' ||
      'onUserInteraction' => AutovalidateMode.onUserInteraction,
      'on_unfocus' || 'onUnfocus' => AutovalidateMode.onUnfocus,
      'on_user_interaction_if_error' ||
      'onUserInteractionIfError' => AutovalidateMode.onUserInteractionIfError,
      _ => null,
    };
    if (mode != null) {
      return mode;
    }
    throw FormatException(
      '${field.name}.autovalidate_mode has unsupported value "$value".',
    );
  }

  DateTime? _dateValue(SmartJsonFieldDefinition field, String key) {
    final value = field.stringValue(key);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value) ??
        (throw FormatException('${field.name}.$key must be an ISO-8601 date.'));
  }
}

List<SmartValidator<T>> _adaptValidators<T>(
  List<SmartValidator<Object?>> validators,
) {
  return <SmartValidator<T>>[
    for (final validator in validators) (value) => validator(value),
  ];
}

List<SmartAsyncValidator<T>> _adaptAsyncValidators<T>(
  List<SmartAsyncValidator<Object?>> validators,
) {
  return <SmartAsyncValidator<T>>[
    for (final validator in validators) (value) => validator(value),
  ];
}

final class _JsonOption {
  const _JsonOption(this.value, this.label);

  factory _JsonOption.fromJson(Object? json, String fieldName) {
    if (json is Map<Object?, Object?>) {
      final value = json['value'];
      final label = json['label'];
      if (label is! String) {
        throw FormatException('$fieldName option.label must be a string.');
      }
      return _JsonOption(value, label);
    }
    if (json == null || json is num || json is bool || json is String) {
      return _JsonOption(json, json.toString());
    }
    throw FormatException('$fieldName options must contain JSON values.');
  }

  final Object? value;
  final String label;
}
