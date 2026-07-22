// ignore_for_file: public_member_api_docs

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'smart_field_handle.dart';

final class _SmartFieldEntry {
  _SmartFieldEntry({
    required this.field,
    required this.sectionOrder,
    required this.registrationOrder,
  });

  final SmartFieldHandle<Object?> field;
  int sectionOrder;
  final int registrationOrder;
}

/// Stores the fields registered with one smart form.
final class SmartFieldRegistry {
  final List<_SmartFieldEntry> _entries = <_SmartFieldEntry>[];
  int _nextRegistrationOrder = 0;

  List<SmartFieldHandle<Object?>> get fields {
    final entries = List<_SmartFieldEntry>.of(_entries)..sort(_compareEntries);
    return List<SmartFieldHandle<Object?>>.unmodifiable(
      entries.map((entry) => entry.field),
    );
  }

  Map<String, Object?> get values => <String, Object?>{
    for (final field in fields) field.name: field.value,
  };

  Future<Map<String, Object?>> resolveResultValues() async {
    final orderedFields = fields;
    final resolvedValues = await Future.wait<Object?>(
      orderedFields.map((field) => field.resolveResultValue()),
    );
    return <String, Object?>{
      for (var index = 0; index < orderedFields.length; index++)
        orderedFields[index].name: resolvedValues[index],
    };
  }

  SmartFieldHandle<Object?>? fieldNamed(String name) {
    for (final entry in _entries) {
      if (entry.field.name == name) {
        return entry.field;
      }
    }
    return null;
  }

  SmartFieldHandle<Object?>? get firstInvalidField {
    for (final field in fields) {
      if (field.enabled && !field.isValid) {
        return field;
      }
    }
    return null;
  }

  bool contains(SmartFieldHandle<Object?> field) {
    return _entryForIdentity(field) != null;
  }

  bool containsGlobalPosition(Offset position) {
    return fields.any((field) => field.containsGlobalPosition(position));
  }

  void register(SmartFieldHandle<Object?> field, {required int sectionOrder}) {
    final existingEntry = _entryForIdentity(field);
    if (existingEntry != null) {
      existingEntry.sectionOrder = sectionOrder;
      return;
    }

    final duplicate = fieldNamed(field.name);
    if (duplicate != null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Duplicate SmartForm field name "${field.name}".'),
        ErrorDescription(
          'Every field registered with the same SmartForm must have a unique '
          'name.',
        ),
        DiagnosticsProperty<Object>('Existing field', duplicate),
        DiagnosticsProperty<Object>('Duplicate field', field),
      ]);
    }

    _entries.add(
      _SmartFieldEntry(
        field: field,
        sectionOrder: sectionOrder,
        registrationOrder: _nextRegistrationOrder++,
      ),
    );
  }

  void unregister(SmartFieldHandle<Object?> field) {
    _entries.removeWhere((entry) => identical(entry.field, field));
  }

  void reset() {
    for (final field in fields) {
      field.reset();
    }
  }

  void clearErrors() {
    for (final field in fields) {
      field.clearError();
    }
  }

  List<SmartFieldHandle<Object?>> dependentsOf(Iterable<String> sourceNames) {
    final sources = sourceNames.toSet();
    return List<SmartFieldHandle<Object?>>.unmodifiable(
      <SmartFieldHandle<Object?>>[
        for (final field in fields)
          if (field.dependencies.any(sources.contains)) field,
      ],
    );
  }

  void validateDependencyGraph({required bool requireKnownFields}) {
    final fieldsByName = <String, SmartFieldHandle<Object?>>{
      for (final field in fields) field.name: field,
    };

    if (requireKnownFields) {
      for (final field in fields) {
        for (final dependency in field.dependencies) {
          if (!fieldsByName.containsKey(dependency)) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                'SmartForm field "${field.name}" has an unknown dependency.',
              ),
              ErrorDescription(
                'No field named "$dependency" is registered with this form.',
              ),
            ]);
          }
        }
      }
    }

    final visiting = <String>{};
    final visited = <String>{};
    final path = <String>[];

    List<String>? visit(String name) {
      if (visiting.contains(name)) {
        final cycleStart = path.indexOf(name);
        return <String>[...path.sublist(cycleStart), name];
      }
      if (visited.contains(name)) {
        return null;
      }

      visiting.add(name);
      path.add(name);
      final field = fieldsByName[name];
      if (field != null) {
        for (final dependency in field.dependencies) {
          if (!fieldsByName.containsKey(dependency)) {
            continue;
          }
          final cycle = visit(dependency);
          if (cycle != null) {
            return cycle;
          }
        }
      }
      path.removeLast();
      visiting.remove(name);
      visited.add(name);
      return null;
    }

    for (final field in fields) {
      final cycle = visit(field.name);
      if (cycle != null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('SmartForm dependency cycle detected.'),
          ErrorDescription(cycle.join(' -> ')),
          ErrorHint(
            'Remove one dependency edge so validation has an acyclic graph.',
          ),
        ]);
      }
    }
  }

  _SmartFieldEntry? _entryForIdentity(SmartFieldHandle<Object?> field) {
    for (final entry in _entries) {
      if (identical(entry.field, field)) {
        return entry;
      }
    }
    return null;
  }

  static int _compareEntries(_SmartFieldEntry a, _SmartFieldEntry b) {
    final sectionComparison = a.sectionOrder.compareTo(b.sectionOrder);
    if (sectionComparison != 0) {
      return sectionComparison;
    }
    return a.registrationOrder.compareTo(b.registrationOrder);
  }
}
