# smart_form_fields

A behavior-first Flutter form package for field registration, synchronous and
asynchronous validation, value collection, and navigation to the first invalid
field.

> This package is under active development and is not ready for production use.

## Quick start

```dart
final formKey = SmartFormKey();

SmartForm(
  key: formKey,
  children: [
    SmartTextField(
      name: 'email',
      decoration: const InputDecoration(labelText: 'Email'),
      validators: <SmartValidator<String>>[
        SmartValidators.required<String>(),
        SmartValidators.email(),
      ],
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
- localized validation messages;
- server-side field error injection.

See [PLAN.md](PLAN.md) for the implementation phases, API decisions, test
matrix, and release gates.

## Example application

The [example](example/) directory contains a complete Material 3 registration
form with synchronous and asynchronous validation, value patching, reset,
server errors, focus-loss validation, first-error navigation, and a custom
boolean field.

```sh
cd example
flutter run
```

## Current status

The package foundation, form key/controller API, immutable result model,
registry, generic custom field, text field, core sync/async validation,
built-in validators, error animations, and first-error navigation are
implemented. Email, password, phone, date, and dropdown convenience fields are
the next milestone.
