import 'dart:collection';

/// Extracts validation errors from a decoded API response.
typedef SmartApiErrorExtractor =
    SmartApiErrorPayload Function(Object? response);

/// Immutable errors discovered while parsing a decoded API response.
final class SmartApiErrorPayload {
  /// Creates a parsed API error payload.
  SmartApiErrorPayload({
    Map<String, List<String>> fieldErrors = const {},
    List<String> generalErrors = const [],
  }) : fieldErrors = UnmodifiableMapView(<String, List<String>>{
         for (final entry in fieldErrors.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       }),
       generalErrors = List<String>.unmodifiable(generalErrors);

  /// Messages grouped by the field name supplied by the API.
  final Map<String, List<String>> fieldErrors;

  /// Messages that are not associated with a particular field.
  final List<String> generalErrors;

  /// Whether at least one field or general error was found.
  bool get hasErrors => fieldErrors.isNotEmpty || generalErrors.isNotEmpty;
}

/// Result of parsing and applying a complete API validation response.
final class SmartApiErrorResult {
  /// Creates an immutable API error application result.
  SmartApiErrorResult({
    required Map<String, List<String>> discoveredFieldErrors,
    required Map<String, String> appliedErrors,
    required Map<String, List<String>> unmappedFieldErrors,
    required List<String> generalErrors,
  }) : discoveredFieldErrors = UnmodifiableMapView(<String, List<String>>{
         for (final entry in discoveredFieldErrors.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       }),
       appliedErrors = UnmodifiableMapView(
         Map<String, String>.of(appliedErrors),
       ),
       unmappedFieldErrors = UnmodifiableMapView(<String, List<String>>{
         for (final entry in unmappedFieldErrors.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       }),
       generalErrors = List<String>.unmodifiable(generalErrors);

  /// Every field error extracted from the response, using API field names.
  final Map<String, List<String>> discoveredFieldErrors;

  /// Errors applied to registered form fields, using form field names.
  final Map<String, String> appliedErrors;

  /// Extracted field errors that did not match a registered form field.
  final Map<String, List<String>> unmappedFieldErrors;

  /// Extracted messages that did not identify a field.
  final List<String> generalErrors;

  /// Whether the response contained at least one validation error.
  bool get hasErrors =>
      discoveredFieldErrors.isNotEmpty || generalErrors.isNotEmpty;
}

/// Default parsing for common backend validation response formats.
abstract final class SmartApiErrors {
  static const Set<String> _containerKeys = <String>{
    'detail',
    'error',
    'errors',
    'field_error',
    'field_errors',
    'validation_error',
    'validation_errors',
    'violations',
  };
  static const Set<String> _fieldKeys = <String>{
    'attribute',
    'field',
    'field_name',
    'key',
    'name',
    'property',
  };
  static const Set<String> _messageKeys = <String>{
    'description',
    'default_message',
    'detail',
    'error_description',
    'error_message',
    'message',
    'messages',
    'msg',
    'reason',
    'title',
  };
  static const Set<String> _generalKeys = <String>{
    'base',
    'general',
    'global',
    'non_field_error',
    'non_field_errors',
  };
  static const Set<String> _metadataKeys = <String>{
    'code',
    'arguments',
    'binding_failure',
    'codes',
    'error_code',
    'extensions',
    'input',
    'locations',
    'object_name',
    'rejected_value',
    'status',
    'success',
    'type',
  };

  /// Parses [response], which should be a decoded map, list, or string.
  ///
  /// Recognized formats include field maps, arrays of field/message objects,
  /// JSON:API `source.pointer` errors, GraphQL-style paths, and nested
  /// `errors`, `validation_errors`, or `field_errors` containers.
  static SmartApiErrorPayload parse(Object? response) {
    final collector = _ApiErrorCollector();
    final foundContainer = _scanForContainers(response, collector);
    if (!foundContainer && _looksLikeDirectFieldMap(response)) {
      _parseErrorNode(response, collector);
    } else if (!foundContainer && _looksLikeErrorList(response)) {
      _parseErrorNode(response, collector);
    }
    return collector.payload;
  }

  static bool _scanForContainers(Object? node, _ApiErrorCollector collector) {
    var found = false;
    if (node is Map<Object?, Object?>) {
      for (final entry in node.entries) {
        final key = _normalizedKey(entry.key);
        if (_containerKeys.contains(key)) {
          _parseErrorNode(entry.value, collector);
          found = true;
        } else if (entry.value is Map<Object?, Object?> ||
            entry.value is List<Object?>) {
          found = _scanForContainers(entry.value, collector) || found;
        }
      }
      if (found) {
        collector.addGeneralAll(_messagesFrom(node));
      }
    } else if (node is List<Object?>) {
      for (final item in node) {
        found = _scanForContainers(item, collector) || found;
      }
    }
    return found;
  }

  static void _parseErrorNode(
    Object? node,
    _ApiErrorCollector collector, {
    String? suggestedField,
  }) {
    if (node is String) {
      if (suggestedField == null || _isGeneralField(suggestedField)) {
        collector.addGeneral(node);
      } else {
        collector.addField(suggestedField, <String>[node]);
      }
      return;
    }
    if (node is List<Object?>) {
      if (suggestedField != null && node.every((item) => item is String)) {
        collector.addField(suggestedField, node.whereType<String>());
        return;
      }
      for (final item in node) {
        _parseErrorNode(item, collector, suggestedField: suggestedField);
      }
      return;
    }
    if (node is! Map<Object?, Object?>) {
      return;
    }

    final explicitField = _fieldNameFrom(node) ?? suggestedField;
    final messages = _messagesFrom(node);
    if (messages.isNotEmpty) {
      if (explicitField == null || _isGeneralField(explicitField)) {
        collector.addGeneralAll(messages);
      } else {
        collector.addField(explicitField, messages);
      }
    }

    for (final entry in node.entries) {
      final rawKey = entry.key;
      if (rawKey is! String) {
        continue;
      }
      final key = _normalizedKey(rawKey);
      if (_fieldKeys.contains(key) ||
          _messageKeys.contains(key) ||
          _metadataKeys.contains(key) ||
          key == 'path' ||
          key == 'loc' ||
          key == 'source') {
        continue;
      }
      if (_containerKeys.contains(key)) {
        _parseErrorNode(entry.value, collector, suggestedField: explicitField);
        continue;
      }
      if (_generalKeys.contains(key)) {
        _parseErrorNode(entry.value, collector);
        continue;
      }
      _parseErrorNode(entry.value, collector, suggestedField: rawKey);
    }
  }

  static String? _fieldNameFrom(Map<Object?, Object?> node) {
    for (final entry in node.entries) {
      if (_fieldKeys.contains(_normalizedKey(entry.key)) &&
          entry.value is String &&
          (entry.value! as String).trim().isNotEmpty) {
        return (entry.value! as String).trim();
      }
    }

    final path = node['path'] ?? node['loc'];
    if (path is List<Object?>) {
      for (final part in path.reversed) {
        if (part is String && part.isNotEmpty) {
          return part;
        }
      }
    } else if (path is String && path.isNotEmpty) {
      return _lastPathSegment(path);
    }

    final source = node['source'];
    if (source is Map<Object?, Object?>) {
      final pointer = source['pointer'];
      if (pointer is String && pointer.isNotEmpty) {
        return _lastPathSegment(pointer);
      }
      final parameter = source['parameter'];
      if (parameter is String && parameter.isNotEmpty) {
        return parameter;
      }
    }
    return null;
  }

  static List<String> _messagesFrom(Map<Object?, Object?> node) {
    final result = <String>[];
    for (final entry in node.entries) {
      if (_messageKeys.contains(_normalizedKey(entry.key))) {
        result.addAll(_messageValues(entry.value));
      }
    }
    return result;
  }

  static Iterable<String> _messageValues(Object? value) sync* {
    if (value is String && value.trim().isNotEmpty) {
      yield value.trim();
    } else if (value is List<Object?>) {
      for (final item in value) {
        yield* _messageValues(item);
      }
    }
  }

  static bool _looksLikeDirectFieldMap(Object? node) {
    if (node is! Map<Object?, Object?> || node.isEmpty) {
      return false;
    }
    for (final entry in node.entries) {
      if (entry.key is! String ||
          _metadataKeys.contains(_normalizedKey(entry.key)) ||
          _messageKeys.contains(_normalizedKey(entry.key)) ||
          !_isErrorValue(entry.value)) {
        return false;
      }
    }
    return true;
  }

  static bool _looksLikeErrorList(Object? node) {
    return node is List<Object?> &&
        node.isNotEmpty &&
        node.every(
          (item) =>
              item is Map<Object?, Object?> && _messagesFrom(item).isNotEmpty,
        );
  }

  static bool _isErrorValue(Object? value) {
    return value is String ||
        value is List<Object?> && value.every((item) => item is String) ||
        value is Map<Object?, Object?>;
  }

  static bool _isGeneralField(String field) {
    return _generalKeys.contains(_normalizedKey(field));
  }

  static String _lastPathSegment(String value) {
    final parts = value
        .split(RegExp(r'[/\.\[\]]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? value : parts.last;
  }

  static String _normalizedKey(Object? value) {
    if (value is! String) {
      return '';
    }
    return value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]}_${match[2]}',
        )
        .replaceAll(RegExp(r'[\s\-.]+'), '_')
        .toLowerCase();
  }
}

final class _ApiErrorCollector {
  final Map<String, List<String>> _fieldErrors = <String, List<String>>{};
  final List<String> _generalErrors = <String>[];

  void addField(String field, Iterable<String> messages) {
    final normalizedField = field.trim();
    if (normalizedField.isEmpty) {
      addGeneralAll(messages);
      return;
    }
    final target = _fieldErrors.putIfAbsent(normalizedField, () => <String>[]);
    for (final message in messages) {
      final normalizedMessage = message.trim();
      if (normalizedMessage.isNotEmpty && !target.contains(normalizedMessage)) {
        target.add(normalizedMessage);
      }
    }
  }

  void addGeneral(String message) => addGeneralAll(<String>[message]);

  void addGeneralAll(Iterable<String> messages) {
    for (final message in messages) {
      final normalized = message.trim();
      if (normalized.isNotEmpty && !_generalErrors.contains(normalized)) {
        _generalErrors.add(normalized);
      }
    }
  }

  SmartApiErrorPayload get payload => SmartApiErrorPayload(
    fieldErrors: _fieldErrors,
    generalErrors: _generalErrors,
  );
}
