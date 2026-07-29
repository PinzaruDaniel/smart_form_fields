import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';
import 'package:smart_form_fields/src/form/smart_field_handle.dart';
import 'package:smart_form_fields/src/form/smart_form_scope.dart';

void main() {
  group('SmartForm access', () {
    testWidgets('supports key-based access', (tester) async {
      final formKey = SmartFormKey();

      await tester.pumpWidget(
        _host(SmartForm(key: formKey, children: const <Widget>[])),
      );

      final result = await formKey.validate();

      expect(result.isValid, isTrue);
      expect(result.values, isEmpty);
      expect(result.errors, isEmpty);
    });

    testWidgets('attaches and detaches an external controller', (tester) async {
      final controller = SmartFormController();

      await tester.pumpWidget(
        _host(SmartForm(controller: controller, children: const <Widget>[])),
      );
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(_host(const SizedBox()));

      expect(controller.isAttached, isFalse);
      expect(controller.validate, throwsStateError);
    });

    testWidgets('rejects one controller attached to two forms', (tester) async {
      final controller = SmartFormController();

      await tester.pumpWidget(
        _host(
          Column(
            children: <Widget>[
              SmartForm(controller: controller, children: const <Widget>[]),
              SmartForm(controller: controller, children: const <Widget>[]),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isA<StateError>());
    });
  });

  group('field registration', () {
    testWidgets('collects values and validates in current widget order', (
      tester,
    ) async {
      final controller = SmartFormController();
      final validationOrder = <String>[];
      var reversed = false;

      Widget buildForm() {
        final fields = <Widget>[
          _TestField(
            key: const ValueKey<String>('first'),
            name: 'first',
            value: 'one',
            validationOrder: validationOrder,
          ),
          _TestField(
            key: const ValueKey<String>('second'),
            name: 'second',
            value: 2,
            validationOrder: validationOrder,
          ),
        ];
        return _host(
          SmartForm(
            controller: controller,
            children: reversed ? fields.reversed.toList() : fields,
          ),
        );
      }

      await tester.pumpWidget(buildForm());
      expect(controller.values, <String, Object?>{'first': 'one', 'second': 2});

      reversed = true;
      await tester.pumpWidget(buildForm());
      await controller.validate();

      expect(validationOrder, <String>['second', 'first']);
      expect(controller.values.keys, <String>['second', 'first']);
    });

    testWidgets('unregisters a dynamically removed field', (tester) async {
      final controller = SmartFormController();

      await tester.pumpWidget(
        _host(
          SmartForm(
            controller: controller,
            children: const <Widget>[
              _TestField(name: 'kept', value: 1),
              _TestField(name: 'removed', value: 2),
            ],
          ),
        ),
      );
      expect(controller.values.keys, <String>['kept', 'removed']);

      await tester.pumpWidget(
        _host(
          SmartForm(
            controller: controller,
            children: const <Widget>[_TestField(name: 'kept', value: 1)],
          ),
        ),
      );

      expect(controller.values, <String, Object?>{'kept': 1});
    });

    testWidgets('rejects duplicate field names', (tester) async {
      await tester.pumpWidget(
        _host(
          const SingleChildScrollView(
            child: SmartForm(
              children: <Widget>[
                _TestField(name: 'email'),
                _TestField(name: 'email'),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (error) => error.toString(),
          'message',
          contains('Duplicate SmartForm field name "email"'),
        ),
      );
    });

    testWidgets('keeps nested forms isolated', (tester) async {
      final outerController = SmartFormController();
      final innerController = SmartFormController();

      await tester.pumpWidget(
        _host(
          SmartForm(
            controller: outerController,
            children: <Widget>[
              const _TestField(name: 'outer', value: 1),
              SmartForm(
                controller: innerController,
                children: const <Widget>[_TestField(name: 'inner', value: 2)],
              ),
            ],
          ),
        ),
      );

      expect(outerController.values, <String, Object?>{'outer': 1});
      expect(innerController.values, <String, Object?>{'inner': 2});
    });
  });

  group('form behavior', () {
    testWidgets('navigates to the first invalid enabled field', (tester) async {
      final controller = SmartFormController();
      final firstKey = GlobalKey<_TestFieldState>();
      final secondKey = GlobalKey<_TestFieldState>();

      await tester.pumpWidget(
        _host(
          SmartForm(
            controller: controller,
            children: <Widget>[
              const _TestField(
                name: 'disabled',
                enabled: false,
                validationError: 'Ignored',
              ),
              _TestField(
                key: firstKey,
                name: 'first',
                validationError: 'Required',
              ),
              _TestField(
                key: secondKey,
                name: 'second',
                validationError: 'Also required',
              ),
            ],
          ),
        ),
      );

      final validation = controller.validate();
      await tester.pumpAndSettle();
      final result = await validation;

      expect(result.isValid, isFalse);
      expect(result.errors, <String, String>{
        'first': 'Required',
        'second': 'Also required',
      });
      expect(firstKey.currentState!.scrollCount, 1);
      expect(firstKey.currentState!.focusCount, 1);
      expect(secondKey.currentState!.scrollCount, 0);
      expect(secondKey.currentState!.focusCount, 0);
    });

    testWidgets('patches values atomically and applies server errors', (
      tester,
    ) async {
      final controller = SmartFormController();

      await tester.pumpWidget(
        _host(
          SmartForm(
            controller: controller,
            children: const <Widget>[
              _TestField(name: 'email'),
              _TestField(name: 'phone'),
            ],
          ),
        ),
      );

      controller.patchValue(<String, Object?>{
        'email': 'person@example.com',
        'phone': '+37360000000',
      });
      await controller.setErrors(<String, String>{
        'email': 'Already registered',
      });

      expect(controller.values, <String, Object?>{
        'email': 'person@example.com',
        'phone': '+37360000000',
      });
      expect(
        await controller.validate(scrollToError: false, focusFirstError: false),
        isA<SmartFormResult>(),
      );
      expect(
        () => controller.patchValue(<String, Object?>{
          'email': 'changed',
          'missing': 'value',
        }),
        throwsArgumentError,
      );
      expect(controller.valueOf<String>('email'), 'person@example.com');
    });

    testWidgets('navigation failures do not change the validation result', (
      tester,
    ) async {
      final controller = SmartFormController();

      await tester.pumpWidget(
        _host(
          SmartForm(
            controller: controller,
            children: const <Widget>[
              _TestField(
                name: 'invalid',
                validationError: 'Required',
                throwOnNavigation: true,
              ),
            ],
          ),
        ),
      );

      final validation = controller.validate();
      await tester.pumpAndSettle();
      final result = await validation;

      expect(result.isValid, isFalse);
      expect(result.errors, <String, String>{'invalid': 'Required'});
    });
  });

  test('SmartFormResult exposes immutable snapshots', () {
    final values = <String, Object?>{'email': 'person@example.com'};
    final result = SmartFormResult(
      isValid: true,
      values: values,
      errors: const <String, String>{},
    );

    values['email'] = 'changed@example.com';

    expect(result.values['email'], 'person@example.com');
    expect(() => result.values['new'] = 'value', throwsUnsupportedError);
  });
}

Widget _host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

class _TestField extends StatefulWidget {
  const _TestField({
    required this.name,
    this.value,
    this.validationError,
    this.enabled = true,
    this.validationOrder,
    this.throwOnNavigation = false,
    super.key,
  });

  final String name;
  final Object? value;
  final String? validationError;
  final bool enabled;
  final List<String>? validationOrder;
  final bool throwOnNavigation;

  @override
  State<_TestField> createState() => _TestFieldState();
}

class _TestFieldState extends State<_TestField>
    implements SmartFieldHandle<Object?> {
  SmartFormRegistrar? _registrar;
  Object? _value;
  String? _error;
  int focusCount = 0;
  int scrollCount = 0;

  @override
  String get name => widget.name;

  @override
  Object? get value => _value;

  @override
  bool get enabled => widget.enabled;

  @override
  bool get excludeFromDraft => false;

  @override
  bool get isValid => _error == null;

  @override
  bool get isDirty => false;

  @override
  bool get isValidating => false;

  @override
  String? get errorText => _error;

  @override
  Set<String> get dependencies => const <String>{};

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registrar = SmartFormScope.of(context).registrar;
    if (!identical(registrar, _registrar)) {
      _registrar?.unregisterField(this);
      _registrar = registrar;
    }
    registrar.registerField(
      this,
      sectionOrder: SmartFormOrderScope.of(context),
    );
  }

  @override
  void didUpdateWidget(_TestField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _registrar?.unregisterField(this);
      _registrar?.registerField(
        this,
        sectionOrder: SmartFormOrderScope.of(context),
      );
    }
  }

  @override
  void dispose() {
    _registrar?.unregisterField(this);
    super.dispose();
  }

  @override
  Future<bool> validate({
    bool animateError = true,
    SmartValidationContext? context,
  }) async {
    widget.validationOrder?.add(name);
    _error = widget.validationError;
    return isValid;
  }

  @override
  Future<Object?> resolveResultValue() async => _value;

  @override
  void setValue(Object? value, {bool notifyDependents = true}) {
    _value = value;
    _error = null;
  }

  @override
  void dependencyDidChange(SmartValidationContext context) {}

  @override
  void reset() {
    _value = widget.value;
    _error = null;
  }

  @override
  void clearError() => _error = null;

  @override
  void setError(String error, {bool animateError = true}) => _error = error;

  @override
  void animateError() {}

  @override
  void focus() {
    focusCount++;
    if (widget.throwOnNavigation) {
      throw StateError('Focus failed');
    }
  }

  @override
  bool containsGlobalPosition(Offset position) => false;

  @override
  Future<void> scrollIntoView() async {
    scrollCount++;
    if (widget.throwOnNavigation) {
      throw StateError('Scroll failed');
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
