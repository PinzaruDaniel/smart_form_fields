# smart_form_fields

A behavior-first Flutter form package for field registration, synchronous and
asynchronous validation, value collection, and navigation to the first invalid
field.

> This package is under active development and is not ready for production use.

## Planned API

```dart
final formKey = SmartFormKey();

SmartForm(
  key: formKey,
  children: [
    SmartEmailField(
      name: 'email',
      labelText: 'Email',
    ),
  ],
);

final result = await formKey.validate();

if (result.isValid) {
  print(result.values['email']);
}
```

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
server errors, first-error navigation, and a custom boolean field.

```sh
cd example
flutter run
```

## Current status

The package foundation, form key/controller API, immutable result model,
registry, generic custom field, text field, and core sync/async validation are
implemented. Built-in validators and first-error navigation hardening are the
next milestones.
