import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../form/smart_form_controller.dart';

/// Converts live form values to and from JSON-safe draft values.
abstract interface class SmartDraftSerializer {
  /// Converts current form [values] into JSON-safe data.
  Map<String, Object?> serialize(Map<String, Object?> values);

  /// Converts stored JSON-safe [values] back into form values.
  Map<String, Object?> deserialize(Map<String, Object?> values);
}

/// Default serializer for JSON values and [DateTime] instances.
final class SmartJsonDraftSerializer implements SmartDraftSerializer {
  /// Creates the default draft serializer.
  const SmartJsonDraftSerializer();

  @override
  Map<String, Object?> serialize(Map<String, Object?> values) =>
      _encodeMap(values);

  @override
  Map<String, Object?> deserialize(Map<String, Object?> values) =>
      _decodeMap(values);

  static Map<String, Object?> _encodeMap(Map<String, Object?> values) =>
      <String, Object?>{
        for (final entry in values.entries) entry.key: _encode(entry.value),
      };

  static Object? _encode(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return <String, Object?>{
        r'$smart_draft_type': 'date_time',
        'value': value.toIso8601String(),
      };
    }
    if (value is Map<String, Object?>) {
      return _encodeMap(value);
    }
    if (value is Iterable<Object?>) {
      return value.map<Object?>(_encode).toList(growable: false);
    }
    throw UnsupportedError(
      'SmartJsonDraftSerializer cannot encode ${value.runtimeType}. '
      'Provide a custom SmartDraftSerializer.',
    );
  }

  static Map<String, Object?> _decodeMap(Map<String, Object?> values) =>
      <String, Object?>{
        for (final entry in values.entries) entry.key: _decode(entry.value),
      };

  static Object? _decode(Object? value) {
    if (value is List<Object?>) {
      return value.map<Object?>(_decode).toList(growable: false);
    }
    if (value is Map<String, Object?>) {
      if (value[r'$smart_draft_type'] == 'date_time') {
        return DateTime.parse(value['value']! as String);
      }
      return _decodeMap(value);
    }
    return value;
  }
}

/// String-based persistence used by [SmartFormDraftController].
abstract interface class SmartDraftStorage {
  /// Reads a stored payload by form [id].
  Future<String?> read(String id);

  /// Writes [payload] for form [id].
  Future<void> write(String id, String payload);

  /// Removes the stored payload for form [id].
  Future<void> delete(String id);
}

/// Reads a draft payload by form id.
typedef SmartDraftRead = FutureOr<String?> Function(String id);

/// Writes a draft [payload] for a form id.
typedef SmartDraftWrite = FutureOr<void> Function(String id, String payload);

/// Deletes a draft payload by form id.
typedef SmartDraftDelete = FutureOr<void> Function(String id);

/// Adapts application-owned persistence callbacks to [SmartDraftStorage].
///
/// This is useful when drafts should be saved through an application's own
/// data/domain/presentation layers, for example an ObjectBox repository or
/// use case exposed by a controller.
final class SmartCallbackDraftStorage implements SmartDraftStorage {
  /// Creates a callback-backed draft storage adapter.
  const SmartCallbackDraftStorage({
    required this.onRead,
    required this.onWrite,
    required this.onDelete,
  });

  /// Callback used when the draft controller reads a payload.
  final SmartDraftRead onRead;

  /// Callback used when the draft controller writes a payload.
  final SmartDraftWrite onWrite;

  /// Callback used when the draft controller deletes a payload.
  final SmartDraftDelete onDelete;

  @override
  Future<String?> read(String id) async => onRead(id);

  @override
  Future<void> write(String id, String payload) async {
    await onWrite(id, payload);
  }

  @override
  Future<void> delete(String id) async {
    await onDelete(id);
  }
}

/// In-memory draft storage suitable for tests and temporary drafts.
final class SmartMemoryDraftStorage implements SmartDraftStorage {
  /// Creates empty in-memory storage.
  SmartMemoryDraftStorage();

  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String id) async => _values[id];

  @override
  Future<void> write(String id, String payload) async {
    _values[id] = payload;
  }

  @override
  Future<void> delete(String id) async {
    _values.remove(id);
  }
}

/// Asynchronous transformation used for encrypted storage adapters.
typedef SmartDraftStringTransform = FutureOr<String> Function(String value);

/// Wraps storage with application-provided encryption and decryption.
final class SmartTransformDraftStorage implements SmartDraftStorage {
  /// Creates a transforming storage adapter.
  const SmartTransformDraftStorage({
    required this.storage,
    required this.encode,
    required this.decode,
  });

  /// Underlying persistence implementation.
  final SmartDraftStorage storage;

  /// Encrypts or otherwise encodes plaintext before writing.
  final SmartDraftStringTransform encode;

  /// Decrypts or otherwise decodes stored text after reading.
  final SmartDraftStringTransform decode;

  @override
  Future<String?> read(String id) async {
    final value = await storage.read(id);
    return value == null ? null : await decode(value);
  }

  @override
  Future<void> write(String id, String payload) async {
    await storage.write(id, await encode(payload));
  }

  @override
  Future<void> delete(String id) => storage.delete(id);
}

/// Migrates draft values from one schema version to the next.
typedef SmartDraftMigration =
    FutureOr<Map<String, Object?>> Function(Map<String, Object?> values);

/// Provides debounced persistence and restoration for one smart form.
final class SmartFormDraftController extends ChangeNotifier {
  /// Creates a draft controller.
  SmartFormDraftController({
    required this.id,
    required this.storage,
    this.serializer = const SmartJsonDraftSerializer(),
    this.autosaveDebounce = const Duration(milliseconds: 500),
    this.schemaVersion = 1,
    this.migrations = const {},
    this.excludedFields = const {},
    this.expiration,
    this.restoreAutomatically = false,
  }) : assert(id.isNotEmpty, 'A draft id cannot be empty.'),
       assert(schemaVersion > 0, 'schemaVersion must be positive.');

  /// Stable storage identifier for this form.
  final String id;

  /// Persistence implementation, optionally backed by encrypted storage.
  final SmartDraftStorage storage;

  /// Converts values to and from JSON-safe data.
  final SmartDraftSerializer serializer;

  /// Delay between the last value change and automatic persistence.
  final Duration autosaveDebounce;

  /// Current application schema version.
  final int schemaVersion;

  /// Migrations keyed by their source version.
  final Map<int, SmartDraftMigration> migrations;

  /// Field names omitted from persisted drafts.
  final Set<String> excludedFields;

  /// Optional maximum age of a stored draft.
  final Duration? expiration;

  /// Whether an available draft is restored immediately after attachment.
  final bool restoreAutomatically;

  SmartFormController? _form;
  Timer? _autosaveTimer;
  Map<String, Object?>? _restorableValues;
  Map<String, Object?>? _observedValues;
  bool _suppressChanges = false;
  bool _ignoreCurrentChanges = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasStoredDraft = false;
  bool _hasRestorableDraft = false;
  bool _hasPendingChanges = false;
  DateTime? _savedAt;
  Object? _lastError;

  /// Whether storage is currently being inspected.
  bool get isLoading => _isLoading;

  /// Whether a draft write is currently running.
  bool get isSaving => _isSaving;

  /// Whether a draft exists in storage.
  bool get hasStoredDraft => _hasStoredDraft;

  /// Whether an unrestored draft is available for a restoration prompt.
  bool get hasRestorableDraft => _hasRestorableDraft;

  /// Whether changed values are waiting to be saved.
  bool get hasPendingChanges => _hasPendingChanges;

  /// Whether navigation should be protected.
  bool get shouldProtectNavigation =>
      !_ignoreCurrentChanges && (_hasPendingChanges || _hasStoredDraft);

  /// Last successful save time.
  DateTime? get savedAt => _savedAt;

  /// Last storage, serialization, or migration failure.
  Object? get lastError => _lastError;

  /// Dirty field names from the attached form.
  Set<String> get dirtyFields => _form?.dirtyFields ?? const <String>{};

  /// Fields currently running asynchronous validation.
  Set<String> get validatingFields =>
      _form?.validatingFields ?? const <String>{};

  /// Whether any attached field is running asynchronous validation.
  bool get isValidating => _form?.isValidating ?? false;

  /// Attaches to a mounted form controller and inspects storage.
  Future<void> attach(SmartFormController form) async {
    if (_form != null && !identical(_form, form)) {
      throw StateError(
        'A SmartFormDraftController cannot attach to multiple forms.',
      );
    }
    if (identical(_form, form)) {
      return;
    }
    _form = form;
    form.addListener(_handleFormChanged);
    _observedValues = Map<String, Object?>.of(form.values);
    await inspect();
  }

  /// Detaches from [form] without deleting its stored draft.
  void detach(SmartFormController form) {
    if (!identical(_form, form)) {
      return;
    }
    _autosaveTimer?.cancel();
    form.removeListener(_handleFormChanged);
    _form = null;
  }

  /// Checks storage for a non-expired, migratable draft.
  Future<void> inspect() async {
    _setLoading(true);
    try {
      final payload = await storage.read(id);
      if (payload == null) {
        _clearStoredState();
        return;
      }
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Draft payload must be a JSON object.');
      }
      final savedAt = DateTime.parse(decoded['saved_at']! as String);
      if (expiration case final expiration?
          when DateTime.now().toUtc().difference(savedAt.toUtc()) >
              expiration) {
        await storage.delete(id);
        _clearStoredState();
        return;
      }

      var version = decoded['schema_version']! as int;
      var values = Map<String, Object?>.from(
        decoded['values']! as Map<String, Object?>,
      );
      if (version > schemaVersion) {
        throw StateError(
          'Draft schema $version is newer than supported schema '
          '$schemaVersion.',
        );
      }
      while (version < schemaVersion) {
        final migration = migrations[version];
        if (migration == null) {
          throw StateError(
            'Missing draft migration from schema $version to ${version + 1}.',
          );
        }
        values = await migration(Map<String, Object?>.of(values));
        version++;
      }

      _restorableValues = serializer.deserialize(values);
      _savedAt = savedAt;
      _hasStoredDraft = true;
      _hasRestorableDraft = true;
      _lastError = null;
      if (restoreAutomatically) {
        await restore();
      }
    } catch (error) {
      _lastError = error;
    } finally {
      _setLoading(false);
    }
  }

  /// Restores known fields from the inspected draft.
  Future<bool> restore() async {
    final form = _form;
    final values = _restorableValues;
    if (form == null || values == null) {
      return false;
    }
    final knownNames = form.fieldStatuses.keys.toSet();
    final applicable = <String, Object?>{
      for (final entry in values.entries)
        if (knownNames.contains(entry.key)) entry.key: entry.value,
    };
    _suppressChanges = true;
    try {
      form.patchValue(applicable);
      _observedValues = Map<String, Object?>.of(form.values);
      _hasRestorableDraft = false;
      _hasPendingChanges = false;
      _lastError = null;
    } finally {
      _suppressChanges = false;
    }
    notifyListeners();
    return true;
  }

  /// Immediately persists current values after applying exclusions.
  Future<void> saveNow() async {
    final form = _form;
    if (form == null) {
      throw StateError('Attach the draft controller before saving.');
    }
    _autosaveTimer?.cancel();
    _isSaving = true;
    notifyListeners();
    try {
      final includedValues = <String, Object?>{
        for (final entry in form.values.entries)
          if (!excludedFields.contains(entry.key)) entry.key: entry.value,
      };
      final serialized = serializer.serialize(includedValues);
      final now = DateTime.now().toUtc();
      await storage.write(
        id,
        jsonEncode(<String, Object?>{
          'schema_version': schemaVersion,
          'saved_at': now.toIso8601String(),
          'values': serialized,
        }),
      );
      _savedAt = now;
      _hasStoredDraft = true;
      _hasRestorableDraft = false;
      _hasPendingChanges = false;
      _lastError = null;
      _observedValues = Map<String, Object?>.of(form.values);
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Deletes the draft and optionally resets the attached form.
  Future<void> discard({bool resetForm = false}) async {
    _autosaveTimer?.cancel();
    await storage.delete(id);
    if (resetForm && _form != null) {
      _suppressChanges = true;
      try {
        _form!.reset();
      } finally {
        _suppressChanges = false;
      }
    }
    _clearStoredState();
    _observedValues = _form == null
        ? null
        : Map<String, Object?>.of(_form!.values);
    _ignoreCurrentChanges = false;
    notifyListeners();
  }

  /// Clears the draft after a successful submission.
  Future<void> markSubmitted() async {
    _autosaveTimer?.cancel();
    await storage.delete(id);
    _clearStoredState();
    _ignoreCurrentChanges = true;
    notifyListeners();
  }

  void _handleFormChanged() {
    if (_suppressChanges || _form == null) {
      notifyListeners();
      return;
    }
    final nextValues = Map<String, Object?>.of(_form!.values);
    if (_deepEquals(nextValues, _observedValues)) {
      notifyListeners();
      return;
    }
    _observedValues = nextValues;
    _ignoreCurrentChanges = false;
    _hasPendingChanges = true;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDebounce, () {
      unawaited(saveNow().catchError((Object _) {}));
    });
    notifyListeners();
  }

  bool _deepEquals(Object? left, Object? right) {
    if (identical(left, right) || left == right) {
      return true;
    }
    if (left is Map && right is Map && left.length == right.length) {
      for (final entry in left.entries) {
        if (!right.containsKey(entry.key) ||
            !_deepEquals(entry.value, right[entry.key])) {
          return false;
        }
      }
      return true;
    }
    if (left is Iterable && right is Iterable) {
      final leftValues = left.toList(growable: false);
      final rightValues = right.toList(growable: false);
      if (leftValues.length != rightValues.length) {
        return false;
      }
      for (var index = 0; index < leftValues.length; index++) {
        if (!_deepEquals(leftValues[index], rightValues[index])) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearStoredState() {
    _restorableValues = null;
    _savedAt = null;
    _hasStoredDraft = false;
    _hasRestorableDraft = false;
    _hasPendingChanges = false;
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    final form = _form;
    if (form != null) {
      form.removeListener(_handleFormChanged);
    }
    _form = null;
    super.dispose();
  }
}

/// Material prompt displayed when an unfinished draft is available.
final class SmartDraftRestoreBanner extends StatelessWidget {
  /// Creates a localized draft restoration banner.
  const SmartDraftRestoreBanner({
    required this.controller,
    required this.message,
    required this.restoreLabel,
    required this.discardLabel,
    this.onRestored,
    this.onDiscarded,
    super.key,
  });

  /// Draft controller observed by this banner.
  final SmartFormDraftController controller;

  /// Prompt text supplied by the application.
  final String message;

  /// Restore action label supplied by the application.
  final String restoreLabel;

  /// Discard action label supplied by the application.
  final String discardLabel;

  /// Called after restoration succeeds.
  final VoidCallback? onRestored;

  /// Called after deletion succeeds.
  final VoidCallback? onDiscarded;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.hasRestorableDraft) {
          return const SizedBox.shrink();
        }
        return MaterialBanner(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (await controller.restore()) {
                  onRestored?.call();
                }
              },
              child: Text(restoreLabel),
            ),
            TextButton(
              onPressed: () async {
                await controller.discard();
                onDiscarded?.call();
              },
              child: Text(discardLabel),
            ),
          ],
        );
      },
    );
  }
}

/// Confirms navigation when an attached form has an unfinished draft.
final class SmartDraftNavigationGuard extends StatefulWidget {
  /// Creates a draft-aware navigation guard.
  const SmartDraftNavigationGuard({
    required this.controller,
    required this.confirmLeave,
    required this.child,
    super.key,
  });

  /// Draft controller that determines whether navigation needs confirmation.
  final SmartFormDraftController controller;

  /// Returns whether the current route may be popped.
  final FutureOr<bool> Function(BuildContext context) confirmLeave;

  /// Protected route content.
  final Widget child;

  @override
  State<SmartDraftNavigationGuard> createState() =>
      _SmartDraftNavigationGuardState();
}

class _SmartDraftNavigationGuardState extends State<SmartDraftNavigationGuard> {
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) => PopScope<Object?>(
        canPop: _allowPop || !widget.controller.shouldProtectNavigation,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop || _allowPop) {
            return;
          }
          if (await widget.confirmLeave(context) &&
              context.mounted &&
              mounted) {
            setState(() => _allowPop = true);
            Navigator.of(context).pop();
          }
        },
        child: child!,
      ),
      child: widget.child,
    );
  }
}
