import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('scrolls nested containers and focuses the first invalid field', (
    tester,
  ) async {
    final formController = SmartFormController();
    final outerScrollController = ScrollController();
    final innerScrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              controller: outerScrollController,
              child: SmartForm(
                controller: formController,
                children: <Widget>[
                  SmartTextField(
                    name: 'valid',
                    initialValue: 'Ready',
                    validators: <SmartValidator>[SmartValidators.required()],
                  ),
                  const SizedBox(height: 500),
                  SizedBox(
                    height: 180,
                    child: SingleChildScrollView(
                      controller: innerScrollController,
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 400),
                          SmartTextField(
                            name: 'invalid',
                            decoration: const InputDecoration(
                              labelText: 'Nested field',
                            ),
                            validators: <SmartValidator>[
                              SmartValidators.required(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final validation = formController.validate();
    await tester.pumpAndSettle();
    final result = await validation;

    expect(result.isValid, isFalse);
    expect(outerScrollController.offset, greaterThan(0));
    expect(innerScrollController.offset, greaterThan(0));
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Nested field'))
          .focusNode!
          .hasFocus,
      isTrue,
    );

    outerScrollController.dispose();
    innerScrollController.dispose();
  });

  testWidgets('shake animation moves an invalid field', (tester) async {
    final controller = SmartFormController();
    const fieldKey = ValueKey<String>('animated-field');

    await tester.pumpWidget(
      _animationApp(
        controller: controller,
        fieldKey: fieldKey,
        disableAnimations: false,
      ),
    );

    final initialPosition = tester.getTopLeft(find.byKey(fieldKey));
    await controller.validate(scrollToError: false, focusFirstError: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    expect(
      tester.getTopLeft(find.byKey(fieldKey)).dx,
      isNot(initialPosition.dx),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(fieldKey)), initialPosition);
  });

  testWidgets('reduced motion disables the error animation', (tester) async {
    final controller = SmartFormController();
    const fieldKey = ValueKey<String>('reduced-motion-field');

    await tester.pumpWidget(
      _animationApp(
        controller: controller,
        fieldKey: fieldKey,
        disableAnimations: true,
      ),
    );

    final initialPosition = tester.getTopLeft(find.byKey(fieldKey));
    await controller.validate(scrollToError: false, focusFirstError: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    expect(tester.getTopLeft(find.byKey(fieldKey)), initialPosition);
  });

  testWidgets('fade animation restores full opacity', (tester) async {
    final controller = SmartFormController();
    const fieldKey = ValueKey<String>('fading-field');

    await tester.pumpWidget(
      _animationApp(
        controller: controller,
        fieldKey: fieldKey,
        disableAnimations: false,
        errorAnimation: SmartErrorAnimation.fade,
      ),
    );

    await controller.validate(scrollToError: false, focusFirstError: false);
    await tester.pump();
    final opacityFinder = find.ancestor(
      of: find.byKey(fieldKey),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(opacityFinder).opacity, 0.45);

    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacityFinder).opacity, 1);
  });

  testWidgets('none leaves an invalid field stationary', (tester) async {
    final controller = SmartFormController();
    const fieldKey = ValueKey<String>('stationary-field');

    await tester.pumpWidget(
      _animationApp(
        controller: controller,
        fieldKey: fieldKey,
        disableAnimations: false,
        errorAnimation: SmartErrorAnimation.none,
      ),
    );

    final initialPosition = tester.getTopLeft(find.byKey(fieldKey));
    await controller.validate(scrollToError: false, focusFirstError: false);
    await tester.pump(const Duration(milliseconds: 90));

    expect(tester.getTopLeft(find.byKey(fieldKey)), initialPosition);
  });

  testWidgets('starts error animation after scrolling completes', (
    tester,
  ) async {
    final controller = SmartFormController();
    final scrollController = ScrollController();
    const fieldKey = ValueKey<String>('deferred-animation-field');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: SingleChildScrollView(
              controller: scrollController,
              child: SmartForm(
                controller: controller,
                focusFirstError: false,
                scrollDuration: const Duration(milliseconds: 600),
                errorAnimation: SmartErrorAnimation.fade,
                children: <Widget>[
                  const SizedBox(height: 500),
                  SmartFormField<String>(
                    name: 'deferred',
                    validators: <SmartValidator>[(_) => 'Invalid'],
                    builder: (context, field) =>
                        const SizedBox(key: fieldKey, width: 100, height: 40),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final validation = controller.validate();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(scrollController.offset, greaterThan(0));
    expect(
      find.ancestor(of: find.byKey(fieldKey), matching: find.byType(Opacity)),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();
    await validation;

    final opacityFinder = find.ancestor(
      of: find.byKey(fieldKey),
      matching: find.byType(Opacity),
    );
    expect(opacityFinder, findsOneWidget);
    expect(tester.widget<Opacity>(opacityFinder).opacity, lessThan(1));

    await tester.pumpAndSettle();
    scrollController.dispose();
  });

  testWidgets('tolerates a field disappearing during async validation', (
    tester,
  ) async {
    final controller = SmartFormController();
    final completion = Completer<String?>();
    late StateSetter updateHost;
    var showField = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return SmartForm(
              controller: controller,
              children: <Widget>[
                if (showField)
                  SmartFormField<String>(
                    name: 'temporary',
                    asyncValidators: <SmartAsyncValidator<String>>[
                      (_) => completion.future,
                    ],
                    builder: (context, field) => Text(
                      field.isValidating ? 'Validating' : 'Temporary field',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );

    final validation = controller.validate();
    await tester.pump();
    expect(find.text('Validating'), findsOneWidget);

    updateHost(() => showField = false);
    await tester.pump();
    completion.complete('Obsolete error');
    await tester.pump();
    final result = await validation;

    expect(result.isValid, isTrue);
    expect(result.values, isEmpty);
    expect(result.errors, isEmpty);
  });
}

Widget _animationApp({
  required SmartFormController controller,
  required Key fieldKey,
  required bool disableAnimations,
  SmartErrorAnimation errorAnimation = SmartErrorAnimation.shake,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: SmartForm(
        controller: controller,
        scrollToFirstError: false,
        focusFirstError: false,
        errorAnimation: errorAnimation,
        children: <Widget>[
          SmartFormField<String>(
            name: 'animated',
            validators: <SmartValidator>[(value) => 'Invalid'],
            builder: (context, field) {
              return SizedBox(key: fieldKey, width: 100, height: 40);
            },
          ),
        ],
      ),
    ),
  );
}
