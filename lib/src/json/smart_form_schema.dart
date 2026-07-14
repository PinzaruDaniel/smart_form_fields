import 'dart:collection';

import '../animation/smart_error_animation.dart';

/// A parsed, immutable form definition received from JSON.
final class SmartFormSchema {
  SmartFormSchema({
    required List<SmartJsonFieldDefinition> fields,
    this.scrollToFirstError,
    this.focusFirstError,
    this.errorAnimation,
  }) : fields = List<SmartJsonFieldDefinition>.unmodifiable(fields);

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

  final List<SmartJsonFieldDefinition> fields;
  final bool? scrollToFirstError;
  final bool? focusFirstError;
  final SmartErrorAnimation? errorAnimation;
}

/// One field in a [SmartFormSchema].
final class SmartJsonFieldDefinition {
  SmartJsonFieldDefinition({
    required this.name,
    required this.type,
    required Map<String, Object?> properties,
    required List<SmartJsonValidatorDefinition> validators,
    required List<String> asyncValidators,
  }) : properties = UnmodifiableMapView(Map<String, Object?>.of(properties)),
       validators = List<SmartJsonValidatorDefinition>.unmodifiable(validators),
       asyncValidators = List<String>.unmodifiable(asyncValidators);

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

  final String name;
  final String type;
  final Map<String, Object?> properties;
  final List<SmartJsonValidatorDefinition> validators;
  final List<String> asyncValidators;

  String? stringValue(String key) => _optionalString(properties[key], key);

  bool boolValue(String key, {required bool fallback}) {
    return _optionalBool(properties[key], key) ?? fallback;
  }

  int? intValue(String key) => _optionalInt(properties[key], key);

  num? numValue(String key) => _optionalNum(properties[key], key);

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
  SmartJsonValidatorDefinition({
    required this.type,
    required Map<String, Object?> properties,
  }) : properties = UnmodifiableMapView(Map<String, Object?>.of(properties));

  factory SmartJsonValidatorDefinition.fromJson(
    Map<String, Object?> json, {
    String path = 'validator',
  }) {
    return SmartJsonValidatorDefinition(
      type: _requiredString(json['type'], '$path.type'),
      properties: json,
    );
  }

  final String type;
  final Map<String, Object?> properties;

  String? get message => _optionalString(properties['message'], 'message');

  String requireString(String key) {
    return _requiredString(properties[key], '$type.$key');
  }

  int requireInt(String key) {
    return _optionalInt(properties[key], '$type.$key') ??
        (throw FormatException('$type.$key is required.'));
  }

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
