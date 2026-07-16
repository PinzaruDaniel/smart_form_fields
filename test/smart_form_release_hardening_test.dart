import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  for (final useMaterial3 in <bool>[false, true]) {
    testWidgets(
      'validates and renders errors with Material ${useMaterial3 ? 3 : 2}',
      (tester) async {
        final controller = SmartFormController();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: useMaterial3),
            home: Scaffold(
              body: SmartForm(
                controller: controller,
                scrollToFirstError: false,
                focusFirstError: false,
                children: <Widget>[
                  SmartTextField(
                    name: 'email',
                    decoration: const InputDecoration(labelText: 'Email'),
                    validators: <SmartValidator<String>>[
                      SmartValidators.required<String>(message: 'Required'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        final result = await controller.validate();
        await tester.pumpAndSettle();

        expect(result.isValid, isFalse);
        expect(find.text('Required'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byType(TextField))
              .decoration!
              .errorText,
          'Required',
        );
      },
    );
  }

  testWidgets('error remains readable with large accessibility text', (
    tester,
  ) async {
    final controller = SmartFormController();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SmartForm(
              controller: controller,
              scrollToFirstError: false,
              focusFirstError: false,
              children: <Widget>[
                SmartTextField(
                  name: 'display_name',
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validators: <SmartValidator<String>>[
                    SmartValidators.required<String>(
                      message: 'Display name is required',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await controller.validate();
    await tester.pumpAndSettle();

    expect(find.text('Display name is required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation error is exposed in the semantics tree', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = SmartFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            scrollToFirstError: false,
            focusFirstError: false,
            children: <Widget>[
              SmartEmailField(
                name: 'email',
                required: true,
                requiredMessage: 'Email is required',
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
      ),
    );

    await controller.validate();
    await tester.pumpAndSettle();

    final semanticsDescription = tester
        .getSemantics(find.byType(TextField))
        .toStringDeep();
    semantics.dispose();

    expect(semanticsDescription, contains('Email is required'));
  });

  testWidgets('keyboard traversal moves focus in widget order', (tester) async {
    final firstFocus = FocusNode(debugLabel: 'first');
    final secondFocus = FocusNode(debugLabel: 'second');
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: SmartForm(
              children: <Widget>[
                SmartTextField(name: 'first', focusNode: firstFocus),
                SmartTextField(name: 'second', focusNode: secondFocus),
              ],
            ),
          ),
        ),
      ),
    );

    firstFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(firstFocus.hasFocus, isFalse);
    expect(secondFocus.hasFocus, isTrue);
  });

  testWidgets('SmartFormKey rejects commands outside its mounted lifecycle', (
    tester,
  ) async {
    final formKey = SmartFormKey();

    expect(() => formKey.values, throwsStateError);
    expect(formKey.validate, throwsStateError);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartForm(key: formKey, children: const <Widget>[]),
      ),
    );
    expect((await formKey.validate()).isValid, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(() => formKey.values, throwsStateError);
  });

  testWidgets('SmartFormKey exposes the complete mounted command surface', (
    tester,
  ) async {
    final formKey = SmartFormKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            key: formKey,
            scrollDuration: Duration.zero,
            children: <Widget>[
              SmartTextField(
                name: 'name',
                initialValue: 'Initial',
                validators: <SmartValidator<String>>[
                  SmartValidators.required<String>(),
                ],
              ),
              const SmartTextField(name: 'city', initialValue: 'Chisinau'),
            ],
          ),
        ),
      ),
    );

    expect(formKey.values['name'], 'Initial');
    expect(formKey.valueOf<String>('city'), 'Chisinau');

    formKey.setValue<String>('name', 'Updated');
    formKey.patchValue(<String, Object?>{'city': 'Balti'});
    await tester.pump();
    expect(formKey.values, <String, Object?>{
      'name': 'Updated',
      'city': 'Balti',
    });

    formKey.setFieldError('name', 'Server error');
    await tester.pump();
    expect(find.text('Server error'), findsOneWidget);
    formKey.clearErrors();
    await tester.pump();
    expect(find.text('Server error'), findsNothing);

    await formKey.setErrors(<String, String>{'city': 'Invalid city'});
    await tester.pump();
    expect(find.text('Invalid city'), findsOneWidget);

    await formKey.scrollToField('name');
    await formKey.focusField('name');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode!
          .hasFocus,
      isTrue,
    );

    formKey.reset();
    await tester.pump();
    expect(formKey.values, <String, Object?>{
      'name': 'Initial',
      'city': 'Chisinau',
    });
    expect((await formKey.validate()).isValid, isTrue);
  });

  testWidgets('controller replacement updates attachment ownership', (
    tester,
  ) async {
    final first = SmartFormController();
    final second = SmartFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: SmartForm(controller: first, children: const <Widget>[]),
      ),
    );
    expect(first.isAttached, isTrue);
    expect(second.isAttached, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartForm(controller: second, children: const <Widget>[]),
      ),
    );
    expect(first.isAttached, isFalse);
    expect(second.isAttached, isTrue);

    first.dispose();
    second.dispose();
  });

  testWidgets('disposed controller rejects commands and reattachment', (
    tester,
  ) async {
    final controller = SmartFormController()..dispose();

    expect(controller.validate, throwsStateError);
    expect(() => controller.values, throwsStateError);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartForm(controller: controller, children: const <Widget>[]),
      ),
    );
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('theme lookup distinguishes inherited and fallback data', (
    tester,
  ) async {
    const data = SmartFormThemeData(
      scrollToFirstError: false,
      focusFirstError: false,
      scrollDuration: Duration(milliseconds: 10),
      scrollCurve: Curves.linear,
      scrollAlignment: 0.5,
      errorAnimation: SmartErrorAnimation.fade,
    );
    SmartFormThemeData? inherited;
    SmartFormThemeData? absent;
    SmartFormThemeData? fallback;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (outerContext) {
            absent = SmartFormTheme.maybeOf(outerContext);
            fallback = SmartFormTheme.of(outerContext);
            return SmartFormTheme(
              data: data,
              child: Builder(
                builder: (innerContext) {
                  inherited = SmartFormTheme.maybeOf(innerContext);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(absent, isNull);
    expect(fallback, const SmartFormThemeData());
    expect(inherited, data);
    expect(inherited.hashCode, data.hashCode);
    expect(data.copyWith(), data);
    expect(
      data.copyWith(
        scrollToFirstError: true,
        focusFirstError: true,
        scrollDuration: const Duration(milliseconds: 20),
        scrollCurve: Curves.easeIn,
        scrollAlignment: 0.8,
        errorAnimation: SmartErrorAnimation.none,
      ),
      isNot(data),
    );
  });

  testWidgets('updated SmartFormTheme data reaches an existing form', (
    tester,
  ) async {
    final controller = SmartFormController();
    late StateSetter updateTheme;
    var focusFirstError = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateTheme = setState;
              return SmartFormTheme(
                data: SmartFormThemeData(
                  scrollToFirstError: false,
                  focusFirstError: focusFirstError,
                ),
                child: SmartForm(
                  controller: controller,
                  children: <Widget>[
                    SmartTextField(
                      name: 'required',
                      validators: <SmartValidator<String>>[
                        SmartValidators.required<String>(),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await controller.validate();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isFalse,
    );

    controller.clearErrors();
    updateTheme(() => focusFirstError = true);
    await tester.pump();
    final validation = controller.validate();
    await tester.pumpAndSettle();
    await validation;

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
  });
}
