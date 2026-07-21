import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../animation/smart_error_animation.dart';

/// An immutable form definition created in Dart or parsed from JSON.
final class SmartFormSchema {
  /// Creates an immutable schema from parsed field definitions and behavior.
  SmartFormSchema({
    required List<SmartFieldDefinition> fields,
    this.scrollToFirstError,
    this.focusFirstError,
    this.errorAnimation,
  }) : fields = List<SmartFieldDefinition>.unmodifiable(fields);

  /// Parses a snake_case JSON object into a validated schema.
  factory SmartFormSchema.fromJson(Map<String, Object?> json) {
    final rawFields = json['fields'];
    if (rawFields is! List<Object?>) {
      throw const FormatException(
        'Smart form JSON must contain a fields list.',
      );
    }

    return SmartFormSchema(
      fields: <SmartFieldDefinition>[
        for (var index = 0; index < rawFields.length; index++)
          SmartFieldDefinition.fromJson(
            _objectMap(rawFields[index], 'fields[$index]'),
            path: 'fields[$index]',
          ),
      ],
      scrollToFirstError: _optionalBool(
        json['scroll_to_first_error'],
        'scroll_to_first_error',
      ),
      focusFirstError: _optionalBool(
        json['focus_first_error'],
        'focus_first_error',
      ),
      errorAnimation: _errorAnimation(json['error_animation']),
    );
  }

  /// Field definitions in display and validation order.
  final List<SmartFieldDefinition> fields;

  /// Optional schema-level first-error scrolling override.
  final bool? scrollToFirstError;

  /// Optional schema-level first-error focus override.
  final bool? focusFirstError;

  /// Optional schema-level error animation override.
  final SmartErrorAnimation? errorAnimation;
}

/// One field in a [SmartFormSchema].
final class SmartFieldDefinition {
  /// Creates an immutable field definition for a built-in or custom [type].
  SmartFieldDefinition({
    required this.name,
    required this.type,
    Map<String, Object?> properties = const {},
    List<SmartValidatorDefinition> validators = const [],
    List<String> asyncValidators = const [],
    Map<String, List<String>> asyncValidatorDependencies = const {},
  }) : properties = UnmodifiableMapView(<String, Object?>{
         'name': name,
         'type': type,
         ...properties,
       }),
       validators = List<SmartValidatorDefinition>.unmodifiable(validators),
       asyncValidators = List<String>.unmodifiable(asyncValidators),
       asyncValidatorDependencies = UnmodifiableMapView(<String, List<String>>{
         for (final entry in asyncValidatorDependencies.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       });

  /// Creates a text field definition directly in Dart.
  factory SmartFieldDefinition.text({
    required String name,
    String? labelText,
    String? hintText,
    String? helperText,
    String? initialValue,
    bool enabled = true,
    bool required = false,
    String? requiredMessage,
    int maxLines = 1,
    AutovalidateMode? autovalidateMode,
    List<SmartValidatorDefinition> validators = const [],
    List<String> asyncValidators = const [],
    Map<String, List<String>> asyncValidatorDependencies = const {},
  }) {
    return SmartFieldDefinition(
      name: name,
      type: 'text',
      properties: _standardFieldProperties(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        initialValue: initialValue,
        enabled: enabled,
        required: required,
        requiredMessage: requiredMessage,
        autovalidateMode: autovalidateMode,
        extra: <String, Object?>{'max_lines': maxLines},
      ),
      validators: validators,
      asyncValidators: asyncValidators,
      asyncValidatorDependencies: asyncValidatorDependencies,
    );
  }

  /// Creates an email field definition directly in Dart.
  factory SmartFieldDefinition.email({
    required String name,
    String? labelText,
    String? hintText,
    String? helperText,
    String? initialValue,
    bool enabled = true,
    bool required = false,
    String? requiredMessage,
    String? invalidEmailMessage,
    AutovalidateMode? autovalidateMode,
    List<SmartValidatorDefinition> validators = const [],
    List<String> asyncValidators = const [],
    Map<String, List<String>> asyncValidatorDependencies = const {},
  }) {
    return SmartFieldDefinition(
      name: name,
      type: 'email',
      properties: _standardFieldProperties(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        initialValue: initialValue,
        enabled: enabled,
        required: required,
        requiredMessage: requiredMessage,
        autovalidateMode: autovalidateMode,
        extra: <String, Object?>{'invalid_email_message': ?invalidEmailMessage},
      ),
      validators: validators,
      asyncValidators: asyncValidators,
      asyncValidatorDependencies: asyncValidatorDependencies,
    );
  }

  /// Creates a phone field definition directly in Dart.
  factory SmartFieldDefinition.phone({
    required String name,
    String? labelText,
    String? hintText,
    String? helperText,
    String? initialValue,
    String? countryCode,
    bool enabled = true,
    bool required = false,
    String? requiredMessage,
    AutovalidateMode? autovalidateMode,
    List<SmartValidatorDefinition> validators = const [],
    List<String> asyncValidators = const [],
    Map<String, List<String>> asyncValidatorDependencies = const {},
  }) {
    return SmartFieldDefinition(
      name: name,
      type: 'phone',
      properties: _standardFieldProperties(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        initialValue: initialValue,
        enabled: enabled,
        required: required,
        requiredMessage: requiredMessage,
        autovalidateMode: autovalidateMode,
        extra: <String, Object?>{'country_code': ?countryCode},
      ),
      validators: validators,
      asyncValidators: asyncValidators,
      asyncValidatorDependencies: asyncValidatorDependencies,
    );
  }

  /// Creates a password field definition directly in Dart.
  factory SmartFieldDefinition.password({
    required String name,
    String? labelText,
    String? hintText,
    String? helperText,
    String? initialValue,
    bool enabled = true,
    bool required = false,
    String? requiredMessage,
    int? minLength = 8,
    String? minLengthMessage,
    bool showVisibilityToggle = true,
    AutovalidateMode? autovalidateMode,
    List<SmartValidatorDefinition> validators = const [],
    List<String> asyncValidators = const [],
    Map<String, List<String>> asyncValidatorDependencies = const {},
  }) {
    return SmartFieldDefinition(
      name: name,
      type: 'password',
      properties: _standardFieldProperties(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        initialValue: initialValue,
        enabled: enabled,
        required: required,
        requiredMessage: requiredMessage,
        autovalidateMode: autovalidateMode,
        extra: <String, Object?>{
          'min_length': ?minLength,
          'min_length_message': ?minLengthMessage,
          'show_visibility_toggle': showVisibilityToggle,
        },
      ),
      validators: validators,
      asyncValidators: asyncValidators,
      asyncValidatorDependencies: asyncValidatorDependencies,
    );
  }

  /// Creates a date field definition directly in Dart.
  factory SmartFieldDefinition.date({
    required String name,
    String? labelText,
    String? hintText,
    String? helperText,
    DateTime? initialValue,
    DateTime? firstDate,
    DateTime? lastDate,
    bool enabled = true,
    bool required = false,
    String? requiredMessage,
    AutovalidateMode? autovalidateMode,
    List<SmartValidatorDefinition> validators = const [],
    List<String> asyncValidators = const [],
    Map<String, List<String>> asyncValidatorDependencies = const {},
  }) {
    return SmartFieldDefinition(
      name: name,
      type: 'date',
      properties: _standardFieldProperties(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        initialValue: initialValue?.toIso8601String(),
        enabled: enabled,
        required: required,
        requiredMessage: requiredMessage,
        autovalidateMode: autovalidateMode,
        extra: <String, Object?>{
          if (firstDate != null) 'first_date': firstDate.toIso8601String(),
          if (lastDate != null) 'last_date': lastDate.toIso8601String(),
        },
      ),
      validators: validators,
      asyncValidators: asyncValidators,
      asyncValidatorDependencies: asyncValidatorDependencies,
    );
  }

  /// Creates a dropdown field definition directly in Dart.
  factory SmartFieldDefinition.dropdown({
    required String name,
    required List<SmartOptionDefinition> options,
    String? labelText,
    String? hintText,
    String? helperText,
    Object? initialValue,
    bool enabled = true,
    bool required = false,
    String? requiredMessage,
    AutovalidateMode? autovalidateMode,
    List<SmartValidatorDefinition> validators = const [],
    List<String> asyncValidators = const [],
    Map<String, List<String>> asyncValidatorDependencies = const {},
  }) {
    return SmartFieldDefinition(
      name: name,
      type: 'dropdown',
      properties: _standardFieldProperties(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        initialValue: initialValue,
        enabled: enabled,
        required: required,
        requiredMessage: requiredMessage,
        autovalidateMode: autovalidateMode,
        extra: <String, Object?>{
          'options': <Map<String, Object?>>[
            for (final option in options) option.toMap(),
          ],
        },
      ),
      validators: validators,
      asyncValidators: asyncValidators,
      asyncValidatorDependencies: asyncValidatorDependencies,
    );
  }

  /// Parses one JSON field object.
  factory SmartFieldDefinition.fromJson(
    Map<String, Object?> json, {
    String path = 'field',
  }) {
    final name = _requiredString(json['name'], '$path.name');
    final type = _requiredString(json['type'], '$path.type');
    final rawValidators = json['validators'] ?? const <Object?>[];
    if (rawValidators is! List<Object?>) {
      throw FormatException('$path.validators must be a list.');
    }
    final rawAsyncValidators = json['async_validators'] ?? const <Object?>[];
    if (rawAsyncValidators is! List<Object?>) {
      throw FormatException('$path.async_validators must be a list.');
    }
    final asyncValidatorNames = <String>[];
    final asyncDependencies = <String, List<String>>{};
    for (var index = 0; index < rawAsyncValidators.length; index++) {
      final value = rawAsyncValidators[index];
      final itemPath = '$path.async_validators[$index]';
      if (value is String) {
        asyncValidatorNames.add(_requiredString(value, itemPath));
        continue;
      }
      final object = _objectMap(value, itemPath);
      final name = _requiredString(object['name'], '$itemPath.name');
      final rawDependsOn = object['depends_on'] ?? const <Object?>[];
      if (rawDependsOn is! List<Object?>) {
        throw FormatException('$itemPath.depends_on must be a list.');
      }
      asyncValidatorNames.add(name);
      asyncDependencies[name] = <String>[
        for (
          var dependencyIndex = 0;
          dependencyIndex < rawDependsOn.length;
          dependencyIndex++
        )
          _requiredString(
            rawDependsOn[dependencyIndex],
            '$itemPath.depends_on[$dependencyIndex]',
          ),
      ];
    }

    return SmartFieldDefinition(
      name: name,
      type: type,
      properties: json,
      validators: <SmartValidatorDefinition>[
        for (var index = 0; index < rawValidators.length; index++)
          SmartValidatorDefinition.fromJson(
            _objectMap(rawValidators[index], '$path.validators[$index]'),
            path: '$path.validators[$index]',
          ),
      ],
      asyncValidators: asyncValidatorNames,
      asyncValidatorDependencies: asyncDependencies,
    );
  }

  /// Unique field name.
  final String name;

  /// Built-in or application-registered field type.
  final String type;

  /// Immutable raw snake_case properties for this field.
  final Map<String, Object?> properties;

  /// Parsed synchronous validator definitions.
  final List<SmartValidatorDefinition> validators;

  /// Names of application-registered asynchronous validators.
  final List<String> asyncValidators;

  /// Explicit dependency names for object-form asynchronous validators.
  final Map<String, List<String>> asyncValidatorDependencies;

  /// Reads an optional string property named [key].
  String? stringValue(String key) => _optionalString(properties[key], key);

  /// Reads a boolean property or returns [fallback] when it is absent.
  bool boolValue(String key, {required bool fallback}) {
    return _optionalBool(properties[key], key) ?? fallback;
  }

  /// Reads an optional integer property named [key].
  int? intValue(String key) => _optionalInt(properties[key], key);

  /// Reads an optional numeric property named [key].
  num? numValue(String key) => _optionalNum(properties[key], key);

  /// Reads an immutable list property, returning an empty list when absent.
  List<Object?> listValue(String key) {
    final value = properties[key];
    if (value == null) {
      return const <Object?>[];
    }
    if (value is! List<Object?>) {
      throw FormatException('$name.$key must be a list.');
    }
    return List<Object?>.unmodifiable(value);
  }
}

/// Configuration for one synchronous validator in JSON.
final class SmartValidatorDefinition {
  /// Creates an immutable validator definition.
  SmartValidatorDefinition({
    required this.type,
    Map<String, Object?> properties = const {},
  }) : properties = UnmodifiableMapView(<String, Object?>{
         'type': type,
         ...properties,
       });

  /// Creates a required validator definition.
  factory SmartValidatorDefinition.required({String? message}) {
    return SmartValidatorDefinition(
      type: 'required',
      properties: _messageProperties(message),
    );
  }

  /// Creates an email validator definition.
  factory SmartValidatorDefinition.email({String? message}) {
    return SmartValidatorDefinition(
      type: 'email',
      properties: _messageProperties(message),
    );
  }

  /// Creates an exact-length validator definition.
  factory SmartValidatorDefinition.length(int value, {String? message}) {
    return SmartValidatorDefinition(
      type: 'length',
      properties: <String, Object?>{
        'value': value,
        ..._messageProperties(message),
      },
    );
  }

  /// Creates a minimum-length validator definition.
  factory SmartValidatorDefinition.minLength(int value, {String? message}) {
    return SmartValidatorDefinition(
      type: 'min_length',
      properties: <String, Object?>{
        'value': value,
        ..._messageProperties(message),
      },
    );
  }

  /// Creates a maximum-length validator definition.
  factory SmartValidatorDefinition.maxLength(int value, {String? message}) {
    return SmartValidatorDefinition(
      type: 'max_length',
      properties: <String, Object?>{
        'value': value,
        ..._messageProperties(message),
      },
    );
  }

  /// Creates a regular-expression validator definition.
  factory SmartValidatorDefinition.pattern(String pattern, {String? message}) {
    return SmartValidatorDefinition(
      type: 'pattern',
      properties: <String, Object?>{
        'pattern': pattern,
        ..._messageProperties(message),
      },
    );
  }

  /// Creates a finite-number validator definition.
  factory SmartValidatorDefinition.number({String? message}) {
    return SmartValidatorDefinition(
      type: 'number',
      properties: _messageProperties(message),
    );
  }

  /// Creates a minimum numeric-value validator definition.
  factory SmartValidatorDefinition.min(num value, {String? message}) {
    return SmartValidatorDefinition(
      type: 'min',
      properties: <String, Object?>{
        'value': value,
        ..._messageProperties(message),
      },
    );
  }

  /// Creates a maximum numeric-value validator definition.
  factory SmartValidatorDefinition.max(num value, {String? message}) {
    return SmartValidatorDefinition(
      type: 'max',
      properties: <String, Object?>{
        'value': value,
        ..._messageProperties(message),
      },
    );
  }

  /// Creates a cross-field equality validator definition.
  factory SmartValidatorDefinition.matchesField(
    String field, {
    String? message,
  }) {
    return SmartValidatorDefinition(
      type: 'matches_field',
      properties: <String, Object?>{
        'field': field,
        ..._messageProperties(message),
      },
    );
  }

  /// Creates a conditionally required validator definition.
  factory SmartValidatorDefinition.requiredWhen({
    required String field,
    required Object? equals,
    String? message,
  }) {
    return SmartValidatorDefinition(
      type: 'required_when',
      properties: <String, Object?>{
        'field': field,
        'equals': equals,
        ..._messageProperties(message),
      },
    );
  }

  /// Parses one JSON validator object.
  factory SmartValidatorDefinition.fromJson(
    Map<String, Object?> json, {
    String path = 'validator',
  }) {
    return SmartValidatorDefinition(
      type: _requiredString(json['type'], '$path.type'),
      properties: json,
    );
  }

  /// Built-in or application-registered validator type.
  final String type;

  /// Immutable raw properties for this validator.
  final Map<String, Object?> properties;

  /// Optional error-message override.
  String? get message => _optionalString(properties['message'], 'message');

  /// Reads a required string property named [key].
  String requireString(String key) {
    return _requiredString(properties[key], '$type.$key');
  }

  /// Reads a required integer property named [key].
  int requireInt(String key) {
    return _optionalInt(properties[key], '$type.$key') ??
        (throw FormatException('$type.$key is required.'));
  }

  /// Reads a required numeric property named [key].
  num requireNum(String key) {
    return _optionalNum(properties[key], '$type.$key') ??
        (throw FormatException('$type.$key is required.'));
  }
}

/// A value and label used by a class-defined dropdown field.
final class SmartOptionDefinition {
  /// Creates a dropdown option.
  const SmartOptionDefinition({required this.value, required this.label});

  /// Value stored in the form result.
  final Object? value;

  /// Human-readable menu label.
  final String label;

  /// Converts this option to the schema representation used by the renderer.
  Map<String, Object?> toMap() => <String, Object?>{
    'value': value,
    'label': label,
  };
}

/// Backwards-compatible name for JSON-oriented integrations.
typedef SmartJsonFieldDefinition = SmartFieldDefinition;

/// Backwards-compatible name for JSON-oriented integrations.
typedef SmartJsonValidatorDefinition = SmartValidatorDefinition;

Map<String, Object?> _standardFieldProperties({
  required String? labelText,
  required String? hintText,
  required String? helperText,
  required Object? initialValue,
  required bool enabled,
  required bool required,
  required String? requiredMessage,
  required AutovalidateMode? autovalidateMode,
  Map<String, Object?> extra = const {},
}) {
  return <String, Object?>{
    'label_text': ?labelText,
    'hint_text': ?hintText,
    'helper_text': ?helperText,
    'initial_value': ?initialValue,
    'enabled': enabled,
    'required': required,
    'required_message': ?requiredMessage,
    'autovalidate_mode': ?autovalidateMode == null
        ? null
        : _autovalidateModeName(autovalidateMode),
    ...extra,
  };
}

String _autovalidateModeName(AutovalidateMode mode) {
  return switch (mode) {
    AutovalidateMode.disabled => 'disabled',
    AutovalidateMode.always => 'always',
    AutovalidateMode.onUserInteraction => 'on_user_interaction',
    AutovalidateMode.onUnfocus => 'on_unfocus',
    AutovalidateMode.onUserInteractionIfError => 'on_user_interaction_if_error',
  };
}

Map<String, Object?> _messageProperties(String? message) {
  return <String, Object?>{'message': ?message};
}

Map<String, Object?> _objectMap(Object? value, String path) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$path must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path keys must be strings.');
    }
    result[entry.key! as String] = entry.value;
  }
  return result;
}

String _requiredString(Object? value, String path) {
  final result = _optionalString(value, path);
  if (result == null || result.isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return result;
}

String? _optionalString(Object? value, String path) {
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$path must be a string.');
  }
  return value;
}

bool? _optionalBool(Object? value, String path) {
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    throw FormatException('$path must be a boolean.');
  }
  return value;
}

int? _optionalInt(Object? value, String path) {
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw FormatException('$path must be an integer.');
  }
  return value;
}

num? _optionalNum(Object? value, String path) {
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw FormatException('$path must be a number.');
  }
  return value;
}

SmartErrorAnimation? _errorAnimation(Object? value) {
  if (value == null) {
    return null;
  }
  final name = _requiredString(value, 'error_animation');
  for (final animation in SmartErrorAnimation.values) {
    if (animation.name == name) {
      return animation;
    }
  }
  throw FormatException('Unsupported error_animation "$name".');
}
