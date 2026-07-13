# smart_form_fields example

A Material 3 registration form demonstrating the package's current API:

- `SmartFormController` validation, reset, value patching, and server errors;
- `SmartTextField` with synchronous and debounced asynchronous validators;
- immutable validation results and first-error navigation;
- a custom boolean field built with `SmartFormField<bool>`.

Run the example from this directory:

```sh
flutter run
```

Use `taken@example.com` to see the asynchronous availability error, or select
**Show server errors** to apply errors returned by a simulated backend.
