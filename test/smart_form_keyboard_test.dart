import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('tapping outside the form unfocuses its active field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              SmartForm(
                children: const <Widget>[SmartTextField(name: 'email')],
              ),
              const TextButton(onPressed: null, child: Text('Outside')),
            ],
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    await tester.tap(find.text('Outside'));
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
  });

  testWidgets('tapping blank space inside the form unfocuses its field', (
    tester,
  ) async {
    const blankKey = ValueKey<String>('blank-space');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            children: const <Widget>[
              SmartTextField(name: 'email'),
              SizedBox(key: blankKey, height: 80, width: 300),
            ],
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    await tester.tapAt(tester.getCenter(find.byKey(blankKey)));
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
  });

  testWidgets('keyboard closing unfocuses and reports visibility', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);
    final visibilityChanges = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            onKeyboardVisibilityChanged: visibilityChanges.add,
            children: const <Widget>[SmartTextField(name: 'email')],
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(visibilityChanges, <bool>[true]);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    await tester.pump();
    expect(visibilityChanges, <bool>[true]);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(visibilityChanges, <bool>[true, false]);
  });

  testWidgets('keyboard dismissal behavior can be disabled', (tester) async {
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SmartForm(
            dismissKeyboardOnTapOutside: false,
            unfocusOnKeyboardDismiss: false,
            children: <Widget>[SmartTextField(name: 'email')],
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();

    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
  });
}
