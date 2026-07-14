# smart_form_fields implementation plan

## 1. Product scope

`smart_form_fields` is a behavior-first Flutter form package. It removes the
repetitive code needed to register fields, validate them, collect values, and
move the user to the first invalid field while leaving visual design under the
application's control.

The first public release supports both normal Flutter widget trees and an
opt-in JSON schema for API-driven forms. The JSON layer maps data to the same
field widgets and validation engine rather than maintaining a parallel form
implementation.

### Version 0.1.0 outcomes

- Fields register with the closest `SmartForm` and unregister safely.
- Sync and async validation are race-safe.
- Validation returns values and field errors.
- The first invalid field is scrolled into view and focused when possible.
- Applications can create custom fields with `SmartFormField<T>`.
- Common text, email, password, phone, date, and dropdown fields are included.
- API responses can describe forms through the opt-in JSON schema layer.
- Validation-message localization is supplied by the application.
- Server errors can be applied to one or many fields.
- Package behavior works with Material 2 and Material 3 styling.

### Deferred features

- `0.2.x`: cross-field dependencies and conditional fields.
- `0.3.x`: submission orchestration and `SmartSubmitButton`.
- Later or separate package: searchable dropdown, multi-select, file/image
  picker, segmented controls, radio cards, date ranges, and currency fields.
- Before `1.0.0`: stable API review, migration guide, accessibility audit,
  production examples, and full platform CI.

## 2. Public API decisions

### Form access

Support both access styles without creating two sources of truth:

```dart
final formKey = SmartFormKey();

SmartForm(
  key: formKey,
  children: const [...],
);

final result = await formKey.validate();
```

```dart
final controller = SmartFormController();

SmartForm(
  controller: controller,
  children: const [...],
);

final result = await controller.validate();
```

`SmartFormKey` should extend `GlobalKey<SmartFormState>` so it is a valid widget
key. Its convenience methods delegate to the mounted state. `SmartFormState`
owns the registry. An external `SmartFormController` attaches to that state and
must reject simultaneous attachment to multiple forms with a clear assertion.

The controller exposes:

```dart
Future<SmartFormResult> validate({
  bool? scrollToError,
  bool? focusFirstError,
});

Map<String, Object?> get values;
T? valueOf<T>(String name);
void setValue<T>(String name, T? value);
void patchValue(Map<String, Object?> values);
void reset();
void clearErrors();
void setFieldError(String name, String error);
Future<void> setErrors(
  Map<String, String> errors, {
  bool scrollToFirstError = false,
});
Future<void> focusField(String name);
Future<void> scrollToField(String name);
```

Unknown names passed to imperative methods should throw a descriptive
`ArgumentError` in all build modes. Duplicate registered names should fail fast
with a `FlutterError` that includes the name and both field widget types.

### Validation contracts

Keep the callable validator types small:

```dart
typedef SmartValidator<T> = String? Function(T? value);
typedef SmartAsyncValidator<T> = Future<String?> Function(T? value);
```

For localized built-in validators, use validator objects or factories that
resolve default messages from the field's `BuildContext` at validation time.
This avoids freezing a translated string when the validator list is created
and allows locale changes to take effect without rebuilding application logic.

Validation order in `0.1.0`:

1. synchronous validators in declaration order;
2. asynchronous validators in declaration order;
3. stop at the first error.

`required` is not secretly reordered. Convenience fields place their generated
required validator first. Custom fields retain the exact order supplied by the
developer.

### Validation result

```dart
class SmartFormResult {
  const SmartFormResult({
    required this.isValid,
    required this.values,
    required this.errors,
  });

  final bool isValid;
  final Map<String, Object?> values;
  final Map<String, String> errors;
}
```

Return unmodifiable snapshots so a later field edit cannot mutate an earlier
result. Values include registered enabled fields by default. Disabled-field
behavior must be documented and covered by tests before release; the proposed
default is to preserve their values but skip their validation.

### Field abstraction

Keep the registry-facing handle internal. The public custom-field surface is
`SmartFormField<T>` plus `SmartFieldController<T>`:

```dart
typedef SmartFieldBuilder<T> = Widget Function(
  BuildContext context,
  SmartFieldController<T> field,
);

class SmartFormField<T> extends StatefulWidget {
  const SmartFormField({
    required this.name,
    required this.builder,
    this.initialValue,
    this.validators = const [],
    this.asyncValidators = const [],
    this.enabled = true,
    this.focusNode,
    this.asyncValidationDebounce,
    super.key,
  });
}
```

The builder controller exposes value, error, touched/dirty/validating state,
`didChange`, `validate`, `reset`, and server-error clearing. It must not expose
registry internals.

## 3. Internal architecture

```text
SmartForm
  SmartFormState
    SmartFieldRegistry
    optional SmartFormController attachment
    inherited SmartFormScope
      SmartFormField<T>
        internal SmartFieldHandle<T>
        SmartFieldController<T>
```

The registry owns no widget lifecycle. It stores field handles that register in
`didChangeDependencies`, re-register if the closest form changes, and unregister
in `dispose`.

Each field handle provides:

```dart
abstract interface class SmartFieldHandle<T> {
  String get name;
  T? get value;
  bool get enabled;
  bool get isValid;
  String? get errorText;
  Future<bool> validate();
  void reset();
  void clearError();
  void setError(String error);
  void focus();
  Future<void> scrollIntoView();
}
```

### Field ordering

Registry insertion order alone is insufficient when keyed widgets are
reordered without being disposed. The implementation must keep a stable entry
per field and refresh its traversal order after widget updates. The milestone
is not complete until tests cover insertion, removal, and reordering of mounted
fields and confirm that validation, values, and first-error navigation follow
current widget order.

Start with Flutter document order rather than screen coordinates. Screen
coordinates are unreliable for horizontal, nested, and temporarily unlaid-out
widgets. If Flutter's public APIs cannot provide reliable document comparison,
make ordering explicit in the `SmartForm` child wrapping layer and document the
`0.1` limitation for fields buried in arbitrary independently built subtrees.

### Async validation

Every validation request gets a monotonically increasing generation number.
Only the latest generation may update `errorText`, `isValidating`, or field
validity. Disposal and value changes invalidate outstanding generations.

Debounce applies to change-triggered validation only. An explicit form
`validate()` bypasses debounce and awaits the current value immediately. Form
validation snapshots the registered field order, validates all enabled fields,
awaits completion, then builds one result. It does not short-circuit after the
first invalid field.

### Scroll and focus

Each field has a private anchor key and may own or receive a `FocusNode`.
Navigation performs these operations in order:

1. wait for error widgets/layout to settle;
2. expand via an optional future extension hook, if configured;
3. call `Scrollable.ensureVisible` on the anchor context;
4. request focus only when the field supports focus;
5. trigger its error animation.

Scrolling and focus failures must not change the validation result. Fields
without focus support scroll only. Reduced-motion settings disable animation
and use a non-animated visibility/focus path.

## 4. Implementation phases

### Phase 0 - package foundation

- Create the Flutter package and example application.
- Set SDK constraints, lint rules, license, changelog, and CI skeleton.
- Add the public barrel file and `src/` layout.
- Add a minimal Material 3 example shell.
- Verify `flutter analyze` and `flutter test` on the empty scaffold.

Exit criteria: package imports cleanly, example runs, and CI has analyzer and
test jobs.

### Phase 1 - form shell and result model

- Implement `SmartForm`, `SmartFormState`, `SmartFormKey`, controller
  attach/detach, inherited scope, and `SmartFormResult`.
- Define lifecycle and disposal rules for internally and externally owned
  controllers.
- Add mounted-state errors for key/controller calls before attachment.

Exit criteria: key and controller APIs address one mounted form and detach
without leaks.

### Phase 2 - field registration

- Implement the internal field handle and registry.
- Register with the closest form, reject duplicates, and unregister on dispose.
- Support lookup by name, value snapshots, dynamic insertion/removal, and
  current widget order.

Exit criteria: registry widget tests cover duplicate names, nested forms,
dynamic fields, keyed reorder, disposal, and lookup.

### Phase 3 - generic custom field

- Implement `SmartFormField<T>` and `SmartFieldController<T>`.
- Add value, initial value, enabled, dirty, touched, error, and reset behavior.
- Define behavior when `initialValue`, name, validators, or enabled changes.
- Integrate optional external `FocusNode` without disposing caller-owned nodes.

Exit criteria: an application can build a fully functional custom field using
only the public API.

### Phase 4 - validation engine

- Add sync and async validator execution.
- Add validating state, generation-based stale-result rejection, and debounce.
- Implement built-in required, email, length, pattern, number, min, and max
  validators.
- Implement form validation, result snapshots, clear errors, and server errors.
- Define when user edits clear a server error; default to clear that field's
  server error on its next value change.

Exit criteria: race-condition tests prove slow obsolete validation cannot
overwrite a newer result, and explicit validation always waits for all fields.

### Phase 5 - first-error navigation and animation

- Add field anchors, focus behavior, and configurable scrolling.
- Implement `none`, `shake`, and `fade` error animations.
- Respect reduced motion.
- Cover long forms, nested scrollables, non-focusable custom fields, and fields
  that disappear during validation.

Exit criteria: widget tests show that the first invalid field in current widget
order becomes visible and receives focus when supported.

### Phase 6 - initial reusable fields

Implement in this order:

1. `SmartTextField`
2. `SmartEmailField`
3. `SmartPasswordField`
4. `SmartPhoneField`
5. `SmartDateField`
6. `SmartDropdownField<T>`

All fields should compose `SmartFormField<T>`, inherit the application's
`InputDecorationTheme`, and forward commonly needed Flutter parameters. Avoid
a phone-number engine in `0.1`; accept formatter and custom validators.

Exit criteria: each wrapper has focused widget tests and no parallel validation
implementation outside `SmartFormField<T>`.

### Phase 7 - theming

- Add lightweight inherited `SmartFormTheme` behavior defaults.
- Keep validation messages configurable through validator arguments.
- Do not bundle English, Romanian, or Russian validation message catalogs.

Exit criteria: form behavior can be configured for a widget subtree, direct
form values take precedence, and no localization delegates are required.

### Phase 8 - example, documentation, and 0.1 release

- Build a polished multi-screen example with a registration form, JSON/API
  form, and controller/custom-field playground.
- For `0.1`, demonstrate confirmation using a custom validator that closes over
  application state; ship `matchesField` only in the dependency milestone.
- Document custom fields, async validation, server errors, controller lifecycle,
  disabled fields, and navigation constraints.
- Add API docs and a complete README quick start.
- Run analyzer, unit/widget tests, example build, and package publication dry
  run.

Exit criteria: a new user can copy the README example into a Flutter app and
use the package without reading internals.

## 5. Post-0.1 milestones

### Version 0.2 - dependencies

- Add validator context with read-only access to form values.
- Add `matchesField` and `requiredWhen`.
- Revalidate dependents when source fields change, with cycle detection.
- Explore `SmartConditionalField` only after dependency invalidation is stable.

Do not implement dependencies by capturing a controller inside built-in
validators; dependency metadata must be explicit so changes can trigger the
correct fields.

### Version 0.3 - submission

- Add submission status and error state to `SmartFormController`.
- Add `SmartForm.onSubmit` and `SmartSubmitButton`.
- Validate before submission, prevent duplicates, expose loading, and preserve
  thrown submission errors.
- Decide cancellation semantics before exposing a public cancellation API.

### Version 1.0 hardening

- Remove experimental names and freeze the supported public surface.
- Reach agreed coverage thresholds with behavior-focused tests.
- Test Android, iOS, web, macOS, and Windows in CI where runners permit.
- Complete accessibility and Material 3 audits.
- Publish migration guidance from all pre-1.0 releases.
- Add several production-sized examples without moving advanced widgets into
  the core package automatically.

## 6. Test matrix

### Unit tests

- Built-in validators and message overrides.
- First-error validation ordering.
- Async success/failure, exceptions, debounce, and stale result races.
- Result immutability and value type preservation.
- Reset, patch, set value, clear error, and server error behavior.
- Dependent validation and cycles when `0.2` begins.

### Widget tests

- Registration, duplicate names, closest form, reorder, and dynamic removal.
- Value updates, enabled fields, and controller/key lifecycle.
- Error rendering, validating state, and animation.
- Focus and scrolling through a long form and nested scrollable.
- Non-focusable field fallback and reduced motion.
- Material 2/3 theme inheritance and behavior-theme changes.

### Integration tests

- Submit a long registration form.
- Confirm the first invalid field becomes visible and focused.
- Confirm async validation completes before a valid result is returned.
- Correct the values and complete a successful application-owned submission.

Golden tests are optional and limited to stable package-owned visuals such as
error/validating states. Most field appearance belongs to Flutter themes and is
better protected with behavioral widget tests.

## 7. Proposed source layout

```text
lib/
  smart_form_fields.dart
  src/
    form/
      smart_form.dart
      smart_form_controller.dart
      smart_form_key.dart
      smart_form_result.dart
      smart_form_scope.dart
      smart_field_registry.dart
    fields/
      smart_form_field.dart
      smart_field_controller.dart
      smart_text_field.dart
      smart_email_field.dart
      smart_phone_field.dart
      smart_password_field.dart
      smart_date_field.dart
      smart_dropdown_field.dart
    validation/
      smart_validator.dart
      smart_async_validator.dart
      smart_validators.dart
    json/
      smart_form_schema.dart
      smart_json_form.dart
    animation/
      smart_error_animation.dart
    theme/
      smart_form_theme.dart
test/
  form/
  fields/
  validation/
  helpers/
example/
  lib/
```

Only intended extension points should be exported from
`lib/smart_form_fields.dart`; the registry, scope, and field handles remain
internal.

## 8. Release gates

Every phase must keep these commands green:

```shell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Before publishing `0.1.0`, also require:

```shell
flutter test --coverage
flutter pub publish --dry-run
```

The release is blocked by any known async race, field lifecycle leak, duplicate
name ambiguity, or first-error ordering bug. Advanced widgets are not release
blockers.
