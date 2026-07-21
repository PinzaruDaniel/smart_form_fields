import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  testWidgets('theme supplies form navigation defaults', (tester) async {
    final controller = SmartFormController();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: SingleChildScrollView(
              controller: scrollController,
              child: SmartFormTheme(
                data: const SmartFormThemeData(
                  scrollToFirstError: false,
                  focusFirstError: false,
                ),
                child: SmartForm(
                  controller: controller,
                  children: <Widget>[
                    const SizedBox(height: 500),
                    SmartTextField(
                      name: 'email',
                      validators: <SmartValidator>[SmartValidators.required()],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final validation = controller.validate();
    await tester.pumpAndSettle();
    await validation;

    expect(scrollController.offset, 0);
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isFalse,
    );
    scrollController.dispose();
  });

  testWidgets('form values override theme defaults', (tester) async {
    final controller = SmartFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartFormTheme(
            data: const SmartFormThemeData(focusFirstError: false),
            child: SmartForm(
              controller: controller,
              focusFirstError: true,
              scrollToFirstError: false,
              children: <Widget>[
                SmartTextField(
                  name: 'email',
                  validators: <SmartValidator>[SmartValidators.required()],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final validation = controller.validate();
    await tester.pumpAndSettle();
    await validation;

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
  });

  test('theme data supports immutable overrides', () {
    const defaults = SmartFormThemeData();
    final updated = defaults.copyWith(
      errorAnimation: SmartErrorAnimation.fade,
      scrollAlignment: 0.5,
    );

    expect(updated.errorAnimation, SmartErrorAnimation.fade);
    expect(updated.scrollAlignment, 0.5);
    expect(updated.scrollDuration, defaults.scrollDuration);
  });
}
