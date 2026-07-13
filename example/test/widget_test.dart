import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields_example/main.dart';

void main() {
  testWidgets('renders the registration example', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'First name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.text('Product updates'), findsOneWidget);
  });

  testWidgets('shows validation errors for an empty submission', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());

    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Please correct 6 field(s).'), findsOneWidget);
  });

  testWidgets('fills and validates the sample account', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());

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
}
