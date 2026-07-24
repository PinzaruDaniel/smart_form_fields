import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_form_fields_example/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the example hub', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());

    expect(find.text('Package examples'), findsOneWidget);
    expect(find.text('Registration form'), findsOneWidget);
    expect(find.text('Item-driven form'), findsOneWidget);
    for (final title in const <String>[
      'Class-defined form',
      'JSON API form',
      'Controller playground',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        250,
        scrollable: _pageScrollable(),
      );
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('validates the item-driven form without deleting its draft', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    expect(find.text('Built entirely from field items'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Display name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Phone'), findsOneWidget);
    expect(find.text('Account type'), findsOneWidget);
    expect(find.text('Product updates'), findsOneWidget);

    final fillButton = find.widgetWithText(TextButton, 'Fill item sample');
    await tester.ensureVisible(fillButton);
    await tester.tap(fillButton);
    await tester.pump();

    expect(find.text('mara@example.com'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    final validateButton = find.widgetWithText(FilledButton, 'Validate items');
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Items form is valid: +37378059426'), findsOneWidget);
    expect(find.text('Draft saved'), findsOneWidget);
  });

  testWidgets('autosaves and clears the item-driven draft', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    final nameField = find.widgetWithText(TextField, 'Display name');
    await tester.enterText(nameField, 'Draft name');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Draft saved'), findsOneWidget);

    final resetButton = find.widgetWithText(TextButton, 'Reset items');
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(find.text('No unfinished draft'), findsOneWidget);
    expect(find.text('Draft name'), findsNothing);
  });

  testWidgets('restores the item-driven draft after an app restart', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    await tester.enterText(
      find.widgetWithText(TextField, 'Display name'),
      'Restart-safe draft',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Draft saved'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    expect(find.text('Restart-safe draft'), findsOneWidget);
    expect(find.text('You have an unfinished item-form draft.'), findsNothing);
    expect(find.text('Draft saved'), findsOneWidget);
  });

  testWidgets('renders the registration example', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'First name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Birth date'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Product updates'), findsOneWidget);
  });

  testWidgets('shows validation errors for an empty submission', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Please correct 8 field(s).'), findsOneWidget);
  });

  testWidgets('validates email after focus leaves the field', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final emailField = find.widgetWithText(TextField, 'Email');
    await tester.ensureVisible(emailField);
    await tester.tap(emailField);
    await tester.enterText(emailField, 'invalid');
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsNothing);

    final phoneField = find.widgetWithText(TextField, 'Phone');
    await tester.ensureVisible(phoneField);
    await tester.tap(phoneField);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('fills and validates the sample account', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final fillButton = find.widgetWithText(TextButton, 'Fill sample');
    await tester.ensureVisible(fillButton);
    await tester.tap(fillButton);
    await tester.pump();

    expect(find.text('ana@example.com'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('Validating…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(
      find.text('Account data is valid for ana@example.com'),
      findsOneWidget,
    );
  });

  testWidgets('keeps both password errors visible after submission', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final fillButton = find.widgetWithText(TextButton, 'Fill sample');
    await tester.ensureVisible(fillButton);
    await tester.tap(fillButton);
    await tester.pump();

    final passwordField = find.widgetWithText(TextField, 'Password');
    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'admin');

    final confirmationField = find.widgetWithText(
      TextField,
      'Confirm password',
    );
    await tester.ensureVisible(confirmationField);
    await tester.enterText(confirmationField, 'different');

    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('builds and validates the JSON API example', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'JSON API form');

    expect(
      find.text('Rendered from a snake_case API response'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Work email'), findsOneWidget);
    expect(find.text('Accept API usage terms'), findsOneWidget);

    final fillButton = find.widgetWithText(TextButton, 'Fill JSON sample');
    await tester.scrollUntilVisible(
      fillButton,
      300,
      scrollable: _pageScrollable(),
    );
    await tester.tap(fillButton);
    await tester.pump();

    expect(find.text('api@example.com'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    final validateButton = find.widgetWithText(
      FilledButton,
      'Validate JSON form',
    );
    await tester.tap(validateButton);
    await tester.pump();
    expect(find.text('Validating JSON…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('JSON values:'), findsOneWidget);
  });

  testWidgets('builds and validates the API model class example', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Class-defined form');

    expect(find.text('Rendered from API model classes'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Display name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm password'), findsOneWidget);

    final fillButton = find.widgetWithText(TextButton, 'Fill class sample');
    await tester.scrollUntilVisible(
      fillButton,
      300,
      scrollable: _pageScrollable(),
    );
    await tester.tap(fillButton);
    await tester.pump();

    final validateButton = find.widgetWithText(
      FilledButton,
      'Validate class form',
    );
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Class schema values:'), findsOneWidget);
  });

  testWidgets('demonstrates controller and bottom-sheet operations', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Controller playground');

    expect(find.text('Imperative form controls'), findsOneWidget);
    expect(find.text('Disabled account ID'), findsOneWidget);

    final patchButton = find.widgetWithText(OutlinedButton, 'Patch values');
    await tester.scrollUntilVisible(
      patchButton,
      300,
      scrollable: _pageScrollable(),
    );
    await tester.tap(patchButton);
    await tester.pump();
    expect(find.text('Smart checkout'), findsOneWidget);

    final picker = find.text('Monthly');
    expect(picker, findsOneWidget);

    final field = find.text('Monthly').first;
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(find.text('Quarterly'), findsOneWidget);
    await tester.tap(find.text('Quarterly'));
    await tester.pumpAndSettle();
    expect(find.text('Quarterly'), findsOneWidget);

    final removeButton = find.widgetWithText(
      OutlinedButton,
      'Remove dynamic field',
    );
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pump();
    expect(
      find.widgetWithText(TextField, 'Dynamic referral code'),
      findsNothing,
    );
  });
}

Future<void> _openExample(WidgetTester tester, String title) async {
  final link = find.text(title);
  await tester.scrollUntilVisible(link, 250, scrollable: _pageScrollable());
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Finder _pageScrollable() {
  return find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
}
