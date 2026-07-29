import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets(
    'autosaves changes after debounce and excludes sensitive fields',
    (tester) async {
      final storage = SmartMemoryDraftStorage();
      final form = SmartFormController();
      final draft = SmartFormDraftController(
        id: 'profile',
        storage: storage,
        autosaveDebounce: const Duration(milliseconds: 100),
        excludedFields: const <String>{'password'},
      );

      await tester.pumpWidget(
        _host(
          form: form,
          draft: draft,
          children: const <Widget>[
            SmartTextField(
              name: 'email',
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SmartTextField(
              name: 'password',
              decoration: InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'person@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret',
      );
      await tester.pump(const Duration(milliseconds: 99));

      expect(await storage.read('profile'), isNull);
      expect(form.dirtyFields, <String>{'email', 'password'});
      expect(draft.hasPendingChanges, isTrue);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      final payload =
          jsonDecode((await storage.read('profile'))!) as Map<String, Object?>;
      final values = payload['values']! as Map<String, Object?>;
      expect(values, <String, Object?>{'email': 'person@example.com'});
      expect(payload['schema_version'], 1);
      expect(draft.hasStoredDraft, isTrue);
      expect(draft.hasPendingChanges, isFalse);
      expect(draft.shouldProtectNavigation, isTrue);

      await draft.markSubmitted();
      expect(await storage.read('profile'), isNull);
      expect(draft.shouldProtectNavigation, isFalse);

      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'new-sensitive-value',
      );
      await tester.pump();
      expect(draft.hasPendingChanges, isFalse);
      expect(draft.shouldProtectNavigation, isFalse);

      draft.dispose();
      form.dispose();
    },
  );

  testWidgets('field-level draft exclusion omits sensitive values', (
    tester,
  ) async {
    final storage = SmartMemoryDraftStorage();
    final form = SmartFormController();
    final draft = SmartFormDraftController(
      id: 'field-exclusions',
      storage: storage,
      autosaveDebounce: const Duration(milliseconds: 100),
    );

    await tester.pumpWidget(
      _host(
        form: form,
        draft: draft,
        children: const <Widget>[
          SmartTextField(
            name: 'email',
            decoration: InputDecoration(labelText: 'Email'),
          ),
          SmartPasswordField(
            name: 'password',
            excludeFromDraft: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret-password',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    final payload =
        jsonDecode((await storage.read('field-exclusions'))!)
            as Map<String, Object?>;
    final values = payload['values']! as Map<String, Object?>;
    expect(values, <String, Object?>{'email': 'person@example.com'});

    draft.dispose();
    form.dispose();
  });

  testWidgets('excluded-only edits do not create pending draft changes', (
    tester,
  ) async {
    final storage = SmartMemoryDraftStorage();
    final form = SmartFormController();
    final draft = SmartFormDraftController(
      id: 'excluded-only',
      storage: storage,
      autosaveDebounce: const Duration(milliseconds: 100),
    );

    await tester.pumpWidget(
      _host(
        form: form,
        draft: draft,
        children: const <Widget>[
          SmartPasswordField(
            name: 'password',
            excludeFromDraft: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret-password',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(draft.hasPendingChanges, isFalse);
    expect(await storage.read('excluded-only'), isNull);

    draft.dispose();
    form.dispose();
  });

  testWidgets('offers and restores a migrated unfinished draft', (
    tester,
  ) async {
    final storage = SmartMemoryDraftStorage();
    await storage.write(
      'migrated-profile',
      jsonEncode(<String, Object?>{
        'schema_version': 1,
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'values': <String, Object?>{'full_name': 'Ana Popescu'},
      }),
    );
    final form = SmartFormController();
    final draft = SmartFormDraftController(
      id: 'migrated-profile',
      storage: storage,
      schemaVersion: 2,
      migrations: <int, SmartDraftMigration>{
        1: (values) => <String, Object?>{'display_name': values['full_name']},
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              SmartDraftRestoreBanner(
                controller: draft,
                message: 'Unfinished profile',
                restoreLabel: 'Restore',
                discardLabel: 'Discard',
              ),
              Expanded(
                child: _host(
                  form: form,
                  draft: draft,
                  children: const <Widget>[
                    SmartTextField(
                      name: 'display_name',
                      decoration: InputDecoration(labelText: 'Display name'),
                    ),
                  ],
                  materialApp: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(draft.hasRestorableDraft, isTrue);
    expect(find.text('Unfinished profile'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(form.values['display_name'], 'Ana Popescu');
    expect(find.text('Ana Popescu'), findsOneWidget);
    expect(draft.hasRestorableDraft, isFalse);
    expect(draft.hasStoredDraft, isTrue);

    draft.dispose();
    form.dispose();
  });

  testWidgets('exposes asynchronous validation state through the form', (
    tester,
  ) async {
    final completion = Completer<String?>();
    final form = SmartFormController();
    final draft = SmartFormDraftController(
      id: 'async-profile',
      storage: SmartMemoryDraftStorage(),
      autosaveDebounce: const Duration(seconds: 1),
    );

    await tester.pumpWidget(
      _host(
        form: form,
        draft: draft,
        children: <Widget>[
          SmartTextField(
            name: 'username',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            asyncValidators: <SmartAsyncValidator<String>>[
              (_) => completion.future,
            ],
          ),
        ],
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pump();

    expect(form.isValidating, isTrue);
    expect(form.validatingFields, <String>{'username'});
    expect(draft.isValidating, isTrue);

    completion.complete(null);
    await tester.pump();

    expect(form.isValidating, isFalse);
    expect(draft.isValidating, isFalse);

    draft.dispose();
    form.dispose();
  });

  testWidgets('navigation guard confirms leaving an unfinished draft', (
    tester,
  ) async {
    final form = SmartFormController();
    final draft = SmartFormDraftController(
      id: 'guarded-profile',
      storage: SmartMemoryDraftStorage(),
      autosaveDebounce: const Duration(seconds: 1),
    );
    var allowLeave = false;
    var confirmationCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SmartDraftNavigationGuard(
                    controller: draft,
                    confirmLeave: (_) {
                      confirmationCount++;
                      return allowLeave;
                    },
                    child: Scaffold(
                      appBar: AppBar(title: const Text('Guarded form')),
                      body: SmartForm(
                        controller: form,
                        draftController: draft,
                        children: const <Widget>[
                          SmartTextField(
                            name: 'name',
                            decoration: InputDecoration(labelText: 'Name'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Changed');
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Guarded form'), findsOneWidget);
    expect(confirmationCount, 1);

    allowLeave = true;
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open form'), findsOneWidget);
    expect(confirmationCount, 2);

    draft.dispose();
    form.dispose();
  });

  test(
    'expires old drafts and supports encrypted storage transforms',
    () async {
      final memory = SmartMemoryDraftStorage();
      final encrypted = SmartTransformDraftStorage(
        storage: memory,
        encode: (value) => base64Encode(utf8.encode(value)),
        decode: (value) => utf8.decode(base64Decode(value)),
      );

      await encrypted.write('encrypted', '{"value":1}');
      expect(await memory.read('encrypted'), isNot('{"value":1}'));
      expect(await encrypted.read('encrypted'), '{"value":1}');

      await memory.write(
        'expired',
        jsonEncode(<String, Object?>{
          'schema_version': 1,
          'saved_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 3))
              .toIso8601String(),
          'values': <String, Object?>{'name': 'Old'},
        }),
      );
      final draft = SmartFormDraftController(
        id: 'expired',
        storage: memory,
        expiration: const Duration(days: 1),
      );

      await draft.inspect();

      expect(draft.hasStoredDraft, isFalse);
      expect(await memory.read('expired'), isNull);
      draft.dispose();
    },
  );

  test(
    'callback storage delegates read, write, and delete operations',
    () async {
      final calls = <String>[];
      final values = <String, String>{};
      final storage = SmartCallbackDraftStorage(
        onRead: (id) {
          calls.add('read:$id');
          return values[id];
        },
        onWrite: (id, payload) {
          calls.add('write:$id:$payload');
          values[id] = payload;
        },
        onDelete: (id) {
          calls.add('delete:$id');
          values.remove(id);
        },
      );

      await storage.write('profile', '{"name":"Ana"}');
      expect(await storage.read('profile'), '{"name":"Ana"}');
      await storage.delete('profile');

      expect(await storage.read('profile'), isNull);
      expect(calls, <String>[
        'write:profile:{"name":"Ana"}',
        'read:profile',
        'delete:profile',
        'read:profile',
      ]);
    },
  );

  test('default serializer round-trips DateTime values', () {
    const serializer = SmartJsonDraftSerializer();
    final date = DateTime.utc(2026, 7, 24, 10, 30);

    final encoded = serializer.serialize(<String, Object?>{'date': date});
    final decoded = serializer.deserialize(encoded);

    expect(decoded['date'], date);
  });
}

Widget _host({
  required SmartFormController form,
  required SmartFormDraftController draft,
  required List<Widget> children,
  bool materialApp = true,
}) {
  final content = SingleChildScrollView(
    child: SmartForm(
      controller: form,
      draftController: draft,
      children: children,
    ),
  );
  if (!materialApp) {
    return content;
  }
  return MaterialApp(home: Scaffold(body: content));
}
