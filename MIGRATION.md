# Migrating to 1.0.0

## String validators

`SmartValidator` now represents a string validator directly. Remove the
`<String>` type argument from validator declarations and factories:

```dart
// Before
final List<SmartValidator<String>> validators = [
  SmartValidators.matchesField<String>('password'),
];

// 1.0.0
final List<SmartValidator> validators = [
  SmartValidators.matchesField('password'),
];
```

For dates, typed dropdowns, and custom values, replace generic
`SmartValidator<T>` usage with `SmartValueValidator<T>` and use
`SmartValueValidators`:

```dart
final List<SmartValueValidator<DateTime>> validators = [
  SmartValueValidators.required<DateTime>(),
];
```

## Declarative forms

`SmartSchemaForm` is the neutral renderer for definitions created from Dart
classes or JSON.

```dart
SmartSchemaForm(
  schema: SmartFormSchema(
    fields: [
      SmartFieldDefinition.email(
        name: 'email',
        labelText: 'Email',
        required: true,
      ),
    ],
  ),
);
```

JSON remains available through `SmartSchemaForm.fromJson`. The previous
`SmartJsonForm`, `SmartJsonFieldDefinition`, `SmartJsonValidatorDefinition`,
and builder names remain as compatibility aliases, but new code should use the
neutral schema names.
