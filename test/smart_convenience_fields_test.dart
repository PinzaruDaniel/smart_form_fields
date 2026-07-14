import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('SmartEmailField supplies email defaults and validation', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: const <Widget>[
            SmartEmailField(
              name: 'email',
              required: true,
              requiredMessage: 'Email is required',
              invalidEmailMessage: 'Invalid email',
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.keyboardType, TextInputType.emailAddress);
    expect(textField.autocorrect, isFalse);
    expect(textField.enableSuggestions, isFalse);

    var result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pumpAndSettle();
    expect(result.errors['email'], 'Email is required');

    await tester.enterText(find.byType(TextField), 'invalid');
    result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pumpAndSettle();
    expect(result.errors['email'], 'Invalid email');
  });

  testWidgets('SmartPasswordField validates length and toggles visibility', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: const <Widget>[
            SmartPasswordField(
              name: 'password',
              initialValue: 'short',
              minLength: 8,
              minLengthMessage: 'Too short',
            ),
          ],
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );

    final result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pumpAndSettle();
    expect(result.errors['password'], 'Too short');

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('SmartPhoneField forwards phone configuration and formatters', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartPhoneField(
              name: 'phone',
              countryCode: '+373 ',
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ],
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.keyboardType, TextInputType.phone);
    expect(textField.decoration!.prefixText, '+373 ');

    await tester.enterText(find.byType(TextField), '12a34');
    await tester.pump();
    expect(controller.valueOf<String>('phone'), '1234');
  });

  testWidgets('SmartDateField validates and synchronizes DateTime values', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartDateField(
              name: 'birthDate',
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              required: true,
              requiredMessage: 'Birth date is required',
              dateFormatter: (context, value) =>
                  '${value.year}-${value.month}-${value.day}',
            ),
          ],
        ),
      ),
    );

    var result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pumpAndSettle();
    expect(result.errors['birthDate'], 'Birth date is required');

    controller.setValue<DateTime>('birthDate', DateTime(2000, 2, 3, 14));
    await tester.pump();

    expect(controller.valueOf<DateTime>('birthDate'), DateTime(2000, 2, 3, 14));
    expect(find.text('2000-2-3'), findsOneWidget);
    result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    expect(result.isValid, isTrue);
  });

  testWidgets('SmartDateField stores a date selected from the picker', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartDateField(
              name: 'date',
              initialValue: DateTime(2020, 1, 10),
              firstDate: DateTime(2020),
              lastDate: DateTime(2020, 1, 31),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(controller.valueOf<DateTime>('date'), DateTime(2020, 1, 15));
  });

  testWidgets('SmartDropdownField collects selections and resets', (
    tester,
  ) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: <Widget>[
            SmartDropdownField<String>(
              name: 'country',
              items: const <String>['Moldova', 'Romania'],
              itemLabelBuilder: (country) => country,
              required: true,
              requiredMessage: 'Country is required',
              decoration: const InputDecoration(labelText: 'Country'),
            ),
          ],
        ),
      ),
    );

    var result = await controller.validate(
      scrollToError: false,
      focusFirstError: false,
    );
    await tester.pumpAndSettle();
    expect(result.errors['country'], 'Country is required');

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moldova').last);
    await tester.pumpAndSettle();

    expect(controller.valueOf<String>('country'), 'Moldova');

    controller.reset();
    await tester.pump();
    expect(controller.valueOf<String>('country'), isNull);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}
