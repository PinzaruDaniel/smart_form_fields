# smart_form_fields

A behavior-first Flutter form package for field registration, synchronous and
asynchronous validation, value collection, and navigation to the first invalid
field.

> This package is under active development and is not ready for production use.

## Installation

Add the package to your application:

```shell
flutter pub add smart_form_fields
```

Then import its single public library:

```dart
import 'package:smart_form_fields/smart_form_fields.dart';
```

## Quick start

```dart
final formKey = SmartFormKey();

SmartForm(
  key: formKey,
  children: [
    SmartEmailField(
      name: 'email',
      required: true,
      decoration: const InputDecoration(labelText: 'Email'),
    ),
  ],
);

final result = await formKey.validate();

if (result.isValid) {
  print(result.values['email']);
}
```

### Validation timing

Fields validate when they lose focus by default. Entering text clears an old
field or server error, but does not show a new validator error while the user is
still typing. Calling `validate()`—for example from a submit button—always
validates every enabled field immediately.

To validate only after the user taps a submit button, set the mode once on the
form. Every descendant field inherits it:

```dart
SmartForm(
  controller: formController,
  autovalidateMode: AutovalidateMode.disabled,
  children: [
    SmartTextField(name: 'first_name', validators: [...]),
    SmartEmailField(name: 'email', required: true),
  ],
);

final result = await formController.validate();
```

An individual field can still override the form default with its own
`autovalidateMode`. `SmartJsonForm` provides the same form-level option, while
the snake_case field property `autovalidate_mode` remains available for a JSON
field override.

Change-time validation remains available per field:

```dart
SmartTextField(
  name: 'username',
  autovalidateMode: AutovalidateMode.onUserInteraction,
  asyncValidationDebounce: const Duration(milliseconds: 400),
  asyncValidators: [...],
);
```

Built-in validators include `required`, `email`, exact/minimum/maximum length,
`pattern`, `number`, `min`, and `max`. Every validator accepts a message
override, and optional fields can omit `required`.

The first release will provide:

- automatic field registration and lifecycle handling;
- synchronous and race-safe asynchronous validation;
- scrolling and focusing the first invalid field;
- immutable validation results and value snapshots;
- custom generic fields and common Material field wrappers;
- opt-in forms generated from API JSON schemas;
- configurable validation messages;
- server-side field error injection.

See [PLAN.md](PLAN.md) for the implementation phases, API decisions, test
matrix, and release gates.

### Form behavior theme

Use `SmartFormTheme` to share scrolling, focus, and error-animation defaults
across multiple forms. Values set directly on `SmartForm` take precedence.

```dart
SmartFormTheme(
  data: const SmartFormThemeData(
    errorAnimation: SmartErrorAnimation.fade,
    scrollToFirstError: true,
  ),
  child: SmartForm(
    children: [...],
  ),
);
```

Validation-message localization remains application-owned. Pass the desired
message to a validator, for example
`SmartValidators.required(message: 'Required')`.

## Form access and controller lifecycle

Use `SmartFormKey` for local, key-based access or `SmartFormController` when a
controller fits the owning widget better. Both expose validation, current
values, value patching, reset, focus/scroll commands, and server errors.

```dart
class RegistrationState extends State<Registration> {
  final formController = SmartFormController();

  @override
  void dispose() {
    formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartForm(
      controller: formController,
      children: const [...],
    );
  }
}
```

A caller-owned controller is not disposed by `SmartForm`. One controller can
be attached to only one mounted form at a time, and commands require it to be
attached.

## Async validation

Async validators return a `Future<String?>`. Explicit form validation always
waits for them. Obsolete results are discarded when a value changes while an
older validation request is still running.

```dart
SmartEmailField(
  name: 'email',
  asyncValidationDebounce: const Duration(milliseconds: 400),
  asyncValidators: [
    (value) async {
      final available = await repository.isEmailAvailable(value);
      return available ? null : 'Email is already registered';
    },
  ],
);
```

The debounce applies to automatic validation only. A submit-triggered
`validate()` call starts immediately.

## Keyboard and focus behavior

`SmartForm` observes keyboard visibility through Flutter view-inset changes.
By default, it unfocuses its active field when the keyboard becomes hidden and
when the user taps outside that field, including blank space inside the form.
Only focus owned by that form is changed.

Moving directly between fields does not create an intermediate unfocus, and a
keyboard height change while switching input types is not treated as dismissal.

```dart
SmartForm(
  dismissKeyboardOnTapOutside: true,
  unfocusOnKeyboardDismiss: true,
  onKeyboardVisibilityChanged: (isVisible) {
    debugPrint('Keyboard visible: $isVisible');
  },
  children: [...],
);
```

Set either behavior flag to `false` when a screen manages focus itself. The
same options are available on `SmartJsonForm`.

## Custom fields

Compose `SmartFormField<T>` when the built-in Material wrappers do not match
the desired interaction. This is also the way to use a bottom sheet, dialog,
or custom picker instead of `SmartDropdownField<T>`.

```dart
SmartFormField<String>(
  name: 'country',
  validators: [SmartValidators.required(message: 'Choose a country')],
  builder: (context, field) {
    return ListTile(
      title: Text(field.value ?? 'Choose country'),
      subtitle: field.errorText == null ? null : Text(field.errorText!),
      onTap: field.enabled
          ? () async {
              final value = await showCountryBottomSheet(context);
              if (value != null) field.didChange(value);
            }
          : null,
    );
  },
);
```

Render `field.errorText` in a custom widget and call `field.didChange` whenever
its value changes. Use `field.isValidating` when the UI should expose async
validation progress.

## Forms from API JSON

Use `SmartJsonForm.fromJson` when an API returns a form definition. The JSON
layer builds the same smart field widgets, so values, validation timing, async
race handling, reset, server errors, and first-error navigation behave exactly
like a widget-authored form.

```dart
final schema = jsonDecode(response.body) as Map<String, Object?>;
final controller = SmartFormController();

SmartJsonForm.fromJson(
  json: schema,
  controller: controller,
  asyncValidators: {
    // JSON references this executable validator by name.
    'emailAvailable': (value) async {
      final available = await repository.isEmailAvailable(value as String?);
      return available ? null : 'Email is already registered';
    },
  },
);
```

Example API response:

```json
{
  "scroll_to_first_error": true,
  "error_animation": "fade",
  "fields": [
    {
      "type": "email",
      "name": "email",
      "label_text": "Email",
      "required": true,
      "required_message": "Email is required",
      "async_validators": ["emailAvailable"]
    },
    {
      "type": "password",
      "name": "password",
      "label_text": "Password",
      "min_length": 8,
      "min_length_message": "Use at least 8 characters"
    },
    {
      "type": "dropdown",
      "name": "country",
      "label_text": "Country",
      "options": [
        {"value": "md", "label": "Moldova"},
        {"value": "ro", "label": "Romania"}
      ]
    }
  ]
}
```

Built-in field types are `text`, `email`, `phone`, `password`, `date`, and
`dropdown`. Validator objects support `required`, `email`, `length`,
`min_length`, `max_length`, `pattern`, `number`, `min`, and `max`; numeric or
length limits use a `value` property.

All JSON property names use snake_case, including `scroll_to_first_error`,
`label_text`, `initial_value`, `required_message`, and `async_validators`.
Autovalidation values also use names such as `on_unfocus` and
`on_user_interaction`.

JSON cannot contain executable Dart code. Register named async validators,
`customValidatorBuilders`, or `customFieldBuilders` in the application for
API-specific behavior. Unknown field and validator types fail explicitly
instead of silently rendering an incomplete form.

## Server errors and value updates

Backend errors can be applied after a request. The next value change clears
the server error for that field.

```dart
await formController.setErrors(
  {
    'email': 'The server rejected this email',
    'phone': 'The server could not verify this number',
  },
  scrollToFirstError: true,
);

formController.patchValue({
  'email': 'person@example.com',
  'country': 'Moldova',
});
```

`patchValue` validates all field names before changing any value. Unknown names
throw instead of leaving the form partially updated.

## Disabled fields and navigation

Disabled fields remain registered and appear in `values`, but validation skips
them. On failed validation, `SmartForm` navigates to the first invalid enabled
field in current widget order. Scrolling and focusing are best-effort and never
change the returned `SmartFormResult`.

Set `scrollToFirstError` or `focusFirstError` to `false` when the surrounding
screen owns navigation. Custom fields that cannot accept keyboard focus still
scroll into view. Reduced-motion platform settings suppress error animation.

## Validation result

`validate()` returns an immutable snapshot. Values preserve their field types,
so text fields return `String?`, date fields return `DateTime?`, and generic
fields return their declared type.

```dart
final result = await formController.validate();
if (!result.isValid) return;

final email = result.values['email'] as String?;
final birthDate = result.values['birthDate'] as DateTime?;
```

## Example application

The [example](example/) directory contains three Material 3 screens: a complete
registration flow, a snake_case JSON/API form, and an imperative controller
playground. Together they demonstrate reusable and custom fields, sync/async
validation, bottom-sheet selection, value updates, dynamic and disabled fields,
reset, server errors, focus/scroll commands, and first-error navigation.

```sh
cd example
flutter run
```

## Current status

The package foundation, form key/controller API, immutable result model,
registry, generic custom field, text field, core sync/async validation,
built-in validators, error animations, and first-error navigation are
implemented. The initial reusable field set now includes text, email, password,
phone, date, and generic dropdown fields. Shared form behavior can be configured
with `SmartFormTheme`, and `SmartJsonForm` can build the same fields from API
schemas. Bundled validation-message localization is intentionally out of scope.
