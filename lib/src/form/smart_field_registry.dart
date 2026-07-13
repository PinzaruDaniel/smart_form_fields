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
