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

  testWidgets('SmartPhoneField renders a country selector inside the input', (
    tester,
  ) async {
    const selectorKey = Key('country-selector');
    const separatorKey = Key('country-separator');

    await tester.pumpWidget(
      _app(
        SmartForm(
          children: const <Widget>[
            SmartPhoneField(
              name: 'phone',
              countryCode: '+373 ',
              countrySelector: SizedBox(key: selectorKey, child: Text('+373')),
              countrySelectorSeparator: VerticalDivider(key: separatorKey),
            ),
          ],
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.prefixIcon, isNotNull);
    expect(field.decoration!.prefixText, isNull);
    expect(find.byKey(selectorKey), findsOneWidget);
    expect(find.byKey(separatorKey), findsOneWidget);
  });

  testWidgets('SmartPhoneField renders a separate country selector', (
    tester,
  ) async {
    const selectorKey = Key('separate-country-selector');

    await tester.pumpWidget(
      _app(
        SmartForm(
          children: const <Widget>[
            SmartPhoneField(
              name: 'phone',
              countrySelector: SizedBox(
                key: selectorKey,
                width: 80,
                child: Text('+373'),
              ),
              countrySelectorLayout: SmartPhoneCountrySelectorLayout.separate,
              countrySelectorSeparator: SizedBox(width: 12),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(selectorKey), findsOneWidget);
    expect(
      find.ancestor(of: find.byType(TextField), matching: find.byType(Row)),
      findsWidgets,
    );
    expect(tester.getTopLeft(find.byType(TextField)).dx, greaterThan(80));
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

  testWidgets('SmartDropdownField does not validate when its menu opens', (
    tester,
  ) async {
    final controller = SmartFormController();
    var validationCalls = 0;

    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          errorAnimation: SmartErrorAnimation.none,
          children: <Widget>[
            SmartDropdownField<String>(
              name: 'country',
              items: const <String>['Blocked', 'Moldova'],
              itemLabelBuilder: (country) => country,
              required: true,
              requiredMessage: 'Country is required',
              decoration: const InputDecoration(labelText: 'Country'),
              validators: <SmartValidator>[
                (value) {
                  validationCalls++;
                  return value == 'Blocked' ? 'Country is unavailable' : null;
                },
              ],
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(validationCalls, 0);
    expect(find.text('Country is required'), findsNothing);
    expect(find.text('Blocked'), findsOneWidget);

    await tester.tap(find.text('Blocked'));
    await tester.pumpAndSettle();

    expect(validationCalls, 1);
    expect(find.text('Country is unavailable'), findsOneWidget);
  });

  testWidgets(
    'SmartDropdownField validates and unfocuses when its menu is dismissed',
    (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _app(
          SmartForm(
            errorAnimation: SmartErrorAnimation.none,
            children: <Widget>[
              SmartDropdownField<String>(
                name: 'country',
                items: const <String>['Moldova', 'Romania'],
                itemLabelBuilder: (country) => country,
                focusNode: focusNode,
                required: true,
                requiredMessage: 'Country is required',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);
      expect(find.text('Country is required'), findsNothing);

      await tester.tapAt(const Offset(790, 590));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);
      expect(find.text('Country is required'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Moldova'), findsOneWidget);
    },
  );
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
