import 'dart:collection';

import '../animation/smart_error_animation.dart';

/// A parsed, immutable form definition received from JSON.
final class SmartFormSchema {
  /// Creates an immutable schema from parsed field definitions and behavior.
  SmartFormSchema({
    required List<SmartJsonFieldDefinition> fields,
    this.scrollToFirstError,
    this.focusFirstError,
    this.errorAnimation,
  }) : fields = List<SmartJsonFieldDefinition>.unmodifiable(fields);

  /// Parses a snake_case JSON object into a validated schema.
  factory SmartFormSchema.fromJson(Map<String, Object?> json) {
    final rawFields = json['fields'];
    if (rawFields is! List<Object?>) {
      throw const FormatException(
        'Smart form JSON must contain a fields list.',
      );
    }

    return SmartFormSchema(
      fields: <SmartJsonFieldDefinition>[
        for (var index = 0; index < rawFields.length; index++)
          SmartJsonFieldDefinition.fromJson(
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
  final List<SmartJsonFieldDefinition> fields;

  /// Optional schema-level first-error scrolling override.
  final bool? scrollToFirstError;

  /// Optional schema-level first-error focus override.
  final bool? focusFirstError;

  /// Optional schema-level error animation override.
  final SmartErrorAnimation? errorAnimation;
}

/// One field in a [SmartFormSchema].
final class SmartJsonFieldDefinition {
  /// Creates an immutable JSON field definition.
  SmartJsonFieldDefinition({
    required this.name,
    required this.type,
    required Map<String, Object?> properties,
    required List<SmartJsonValidatorDefinition> validators,
    required List<String> asyncValidators,
  }) : properties = UnmodifiableMapView(Map<String, Object?>.of(properties)),
       validators = List<SmartJsonValidatorDefinition>.unmodifiable(validators),
       asyncValidators = List<String>.unmodifiable(asyncValidators);

  /// Parses one JSON field object.
  factory SmartJsonFieldDefinition.fromJson(
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

    return SmartJsonFieldDefinition(
      name: name,
      type: type,
      properties: json,
      validators: <SmartJsonValidatorDefinition>[
        for (var index = 0; index < rawValidators.length; index++)
          SmartJsonValidatorDefinition.fromJson(
            _objectMap(rawValidators[index], '$path.validators[$index]'),
            path: '$path.validators[$index]',
          ),
      ],
      asyncValidators: <String>[
        for (var index = 0; index < rawAsyncValidators.length; index++)
          _requiredString(
            rawAsyncValidators[index],
            '$path.async_validators[$index]',
          ),
      ],
    );
  }

  /// Unique field name.
  final String name;

  /// Built-in or application-registered field type.
  final String type;

  /// Immutable raw snake_case properties for this field.
  final Map<String, Object?> properties;

  /// Parsed synchronous validator definitions.
  final List<SmartJsonValidatorDefinition> validators;

  /// Names of application-registered asynchronous validators.
  final List<String> asyncValidators;

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
final class SmartJsonValidatorDefinition {
  /// Creates an immutable validator definition.
  SmartJsonValidatorDefinition({
    required this.type,
    required Map<String, Object?> properties,
  }) : properties = UnmodifiableMapView(Map<String, Object?>.of(properties));

  /// Parses one JSON validator object.
  factory SmartJsonValidatorDefinition.fromJson(
    Map<String, Object?> json, {
    String path = 'validator',
  }) {
    return SmartJsonValidatorDefinition(
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
