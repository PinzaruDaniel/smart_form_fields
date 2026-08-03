# smart_form_fields

A behavior-first Flutter form package for field registration, synchronous and
asynchronous validation, value collection, and navigation to the first invalid
field.

The 0.1 release provides a tested foundation for production Flutter forms. The
public API remains pre-1.0 and may evolve through documented minor releases.

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
`autovalidateMode`. `SmartSchemaForm` provides the same form-level option, while
the snake_case field property `autovalidate_mode` remains available for a JSON
field override.

Dropdown menus temporarily move focus while opening. To avoid showing a
required error or interrupting the first tap, dropdowns interpret the default
`onUnfocus` mode as validation after selection or after dismissing the menu.
Dismissal also releases the dropdown's restored focus, so the next control
responds to its first tap.

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

`SmartValidator` is string-first, so normal fields do not need a generic type:

```dart
final SmartValidator validator = SmartValidators.minLength(8);
```

Dates, typed dropdowns, and custom value fields use
`SmartValueValidator<T>` with `SmartValueValidators`:

```dart
final SmartValueValidator<DateTime> validator =
    SmartValueValidators.required<DateTime>();
```

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
matrix, and release gates. Existing users should also see
[MIGRATION.md](MIGRATION.md) for the 1.0 validator and schema naming changes.

### Form behavior theme

Use `SmartFormTheme` to share scrolling, focus, and error-animation defaults
across multiple forms. Values set directly on `SmartForm` take precedence.

```dart
SmartFormTheme(
  data: const SmartFormThemeData(
    errorAnimation: SmartErrorAnimation.slide,
    scrollToFirstError: true,
  ),
  child: SmartForm(
    children: [...],
  ),
);
```

Built-in error animations are `none`, `shake`, `fade`, `slide`, `scale`, and
`pulse`. Reduced-motion accessibility settings disable motion automatically.

Use `errorAnimationBuilder` for application-owned animation wrappers:

```dart
SmartForm(
  errorAnimationBuilder: (context, child, animation) {
    return RotationTransition(
      turns: Tween<double>(begin: -0.01, end: 0).animate(animation),
      child: child,
    );
  },
  children: [...],
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

## Cross-field dependencies

Built-in dependent validators declare the source field explicitly. After a
dependent field has been validated once, changing its source automatically
revalidates it. Before its first validation, dependency changes do not expose
premature errors.

```dart
SmartPasswordField(
  name: 'confirm_password',
  validators: [
    SmartValidators.matchesField(
      'password',
      message: 'Passwords do not match',
    ),
  ],
);

SmartTextField(
  name: 'company_name',
  validators: [
    SmartValidators.requiredWhen(
      field: 'account_type',
      equals: AccountType.business,
      message: 'Company name is required',
    ),
  ],
);
```

Create application-specific rules with a read-only value snapshot. Every field
read from the context should be listed in `dependsOn` so changes can trigger
revalidation:

```dart
SmartValidators.dependent(
  dependsOn: const ['country'],
  validator: (value, context) {
    final country = context.valueOf<String>('country');
    return isCityAllowed(country, value) ? null : 'Invalid city';
  },
);
```

Async dependent validation uses the same contract and retains stale-result
protection:

```dart
SmartAsyncValidators.dependent<String>(
  dependsOn: const ['country'],
  validator: (value, context) async {
    return repository.validateCity(
      country: context.valueOf<String>('country'),
      city: value,
    );
  },
);
```

Unknown dependency names and dependency cycles fail with descriptive errors
before explicit validation runs. `patchValue` applies all values before
revalidating dependents, so validators see the final snapshot.

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
same options are available on `SmartSchemaForm`.

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

## Forms from API model classes

Use `SmartSchemaForm.fromClasses` when an API response has already been decoded
into application DTOs such as `EmailField`, `PasswordField`, or a heterogeneous
`List<ApiField>`. Supply one typed mapper that tells the package how each API
model maps to a built-in field definition:

```dart
sealed class ApiField {
  const ApiField(this.name, this.label);
  final String name;
  final String label;
}

final class EmailField extends ApiField {
  const EmailField(super.name, super.label, {required this.required});
  final bool required;
}

final fields = response.fields; // List<ApiField> created by your API client.

SmartSchemaForm.fromClasses<ApiField>(
  fields: fields,
  controller: formController,
  fieldMapper: (field) => switch (field) {
    EmailField field => SmartFieldDefinition.email(
        name: field.name,
        labelText: field.label,
        required: field.required,
      ),
    PasswordField field => SmartFieldDefinition.password(
        name: field.name,
        labelText: field.label,
        minLength: field.minimumLength,
      ),
    DropdownField field => SmartFieldDefinition.dropdown(
        name: field.name,
        labelText: field.label,
        options: [
          for (final option in field.options)
            SmartOptionDefinition(value: option.value, label: option.label),
        ],
      ),
  },
);
```

Flutter does not provide runtime reflection for arbitrary application classes,
so the mapper is explicit and type-safe. Define it once for the API model
family; the package then handles field rendering, registration, validation,
values, dependencies, scrolling, and focus for every returned list.

## Forms from API JSON

Use `SmartSchemaForm.fromJson` when an API returns a form definition. The JSON
layer builds the same smart field widgets, so values, validation timing, async
race handling, reset, server errors, and first-error navigation behave exactly
like a widget-authored form.

```dart
final schema = jsonDecode(response.body) as Map<String, Object?>;
final controller = SmartFormController();

SmartSchemaForm.fromJson(
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

Dependent validator objects use snake_case types and properties:

```json
{
  "type": "matches_field",
  "field": "password",
  "message": "Passwords do not match"
}
```

```json
{
  "type": "required_when",
  "field": "account_type",
  "equals": "business",
  "message": "Company name is required"
}
```

Named async validators can declare JSON-owned dependency metadata while the
application still supplies the executable Dart callback:

```json
"async_validators": [
  {
    "name": "username_available",
    "depends_on": ["account_type"]
  }
]
```

All JSON property names use snake_case, including `scroll_to_first_error`,
`label_text`, `initial_value`, `required_message`, and `async_validators`.
Autovalidation values also use names such as `on_unfocus` and
`on_user_interaction`.

JSON cannot contain executable Dart code. Register named async validators,
`customValidatorBuilders`, or `customFieldBuilders` in the application for
API-specific behavior. Unknown field and validator types fail explicitly
instead of silently rendering an incomplete form.

## Server errors and value updates

Pass the complete decoded backend response to `setErrorsFromResponse`. The
default parser recursively finds common `errors`, `validation_errors`, and
`field_errors` containers, direct field maps, arrays of field/message objects,
JSON:API pointers, and GraphQL paths. The next value change clears the applied
server error for that field.

```dart
final apiErrors = await formController.setErrorsFromResponse(
  responseBody,
  fieldAliases: {
    'phone_number': 'phone',
  },
  scrollToFirstError: true,
);

showGlobalErrors(apiErrors.generalErrors);
logUnmappedErrors(apiErrors.unmappedFieldErrors);

formController.patchValue({
  'email': 'person@example.com',
  'country': 'Moldova',
});
```

Field names are matched exactly first and then normalized, so `first_name`
maps to `firstName`. Dotted paths and bracket paths use their last component.
Multiple messages for one field are joined with a newline by default; customize
this with `messageSeparator`.

For an uncommon response shape, pass an `extractor` that returns a
`SmartApiErrorPayload`. `SmartApiErrorResult` always reports all discovered,
applied, unmapped, and fieldless/general errors. The existing `setErrors` API
remains available when the application already has a simple field-error map.

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
When form validation navigates to an invalid field, its error animation starts
only after scrolling and focus navigation finish.

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

## Country-aware phone fields

`SmartPhoneField` accepts any application-owned country selector. It can live
inside the decorated input with a vertical divider:

```dart
SmartPhoneField(
  name: 'phone',
  countrySelector: TextButton(
    onPressed: showCountryBottomSheet,
    child: Text('+${selectedCountry.phoneCode}'),
  ),
  countrySelectorSeparator: const VerticalDivider(width: 1),
  inputFormatters: [
    LibPhonenumberTextFormatter(
      country: selectedCountry,
      phoneNumberFormat: PhoneNumberFormat.national,
      inputContainsCountryCode: false,
    ),
  ],
  valueParser: (formatted) async {
    final parsed = await getFormattedParseResult(
      formatted,
      selectedCountry,
      phoneNumberFormat: PhoneNumberFormat.national,
    );
    return SmartPhoneValue(
      formatted: parsed?.formattedNumber ?? formatted,
      e164: parsed?.e164,
    );
  },
);
```

With Moldova selected, the formatter can display `780 59 426` while the
selector displays `+373`. Set
`countrySelectorLayout: SmartPhoneCountrySelectorLayout.separate` to render the
selector as another container in the same row. The selector is intentionally a
widget supplied by the app, so it may open a dropdown, dialog, or bottom sheet.

For localized country names, load the country list through your localized
`flutter_libphonenumber` implementation using the app locale, then rebuild the
field with the selected `CountryWithPhoneCode`. Keeping this adapter app-side
also lets apps without native phone metadata continue using
`smart_form_fields` on every supported Flutter platform.

Validation waits for `valueParser`. When it is configured, the result contains
both representations while live controller values and validators continue to
use the formatted string:

```dart
final result = await formController.validate();
final phone = result.values['phone'] as SmartPhoneValue;

print(phone.formatted); // 780 59 426
print(phone.e164);      // +37378059426
```

Without `valueParser`, `result.values['phone']` remains a `String` for backward
compatibility.

## Field view items

Reusable field configuration can be moved into an immutable view item:

```dart
final phoneItem = SmartPhoneFieldViewItem(
  name: 'phone',
  required: true,
  requiredMessage: 'Phone is required',
  countrySelector: countrySelector,
  countrySelectorSeparator: const VerticalDivider(width: 1),
  decoration: const InputDecoration(
    labelText: 'Phone',
    hintText: '60 123 456',
  ),
  inputFormatters: phoneFormatters,
  valueParser: parsePhoneValue,
);

SmartPhoneField(item: phoneItem);
```

Direct parameters remain supported and override values from the item. Forms can
also build a complete vertical list of items and insert consistent spacing:

```dart
SmartForm(
  controller: formController,
  items: [
    phoneItem,
    SmartWidgetFieldViewItem(
      name: 'custom_field',
      builder: (_) => const MyCustomSmartField(),
    ),
  ],
  itemSeparatorHeight: 16,
);
```

Use either `children` or `items` on one `SmartForm`. The existing `children`
API remains unchanged.

## Draft persistence

Attach a draft controller to an existing `SmartFormController`:

```dart
final formController = SmartFormController();
final draftController = SmartFormDraftController(
  id: 'edit-profile',
  storage: secureDraftStorage,
  serializer: const SmartJsonDraftSerializer(),
  autosaveDebounce: const Duration(milliseconds: 500),
  schemaVersion: 3,
  migrations: {
    1: migrateProfileV1ToV2,
    2: migrateProfileV2ToV3,
  },
  excludedFields: {'password', 'card_cvc'},
  expiration: const Duration(days: 7),
);

SmartForm(
  controller: formController,
  draftController: draftController,
  children: fields,
);
```

The draft controller provides debounced autosaving, manual saving, draft
inspection and restoration, expiration, sequential schema migration,
field-level dirty state, async-validation state, sensitive-field exclusions,
and explicit `discard()` and `markSubmitted()` lifecycle methods.

```dart
await draftController.saveNow();
await draftController.restore();
await draftController.discard(resetForm: true);
await draftController.markSubmitted();

print(draftController.dirtyFields);
print(draftController.validatingFields);
```

Validation alone should not call `markSubmitted()`. Call it only after the
backend accepts the submission, because it permanently deletes the stored
draft. Set `restoreAutomatically: true` to apply a stored draft during
attachment; otherwise present `SmartDraftRestoreBanner` for an explicit choice.

Use `SmartDraftRestoreBanner` for an application-localized unfinished-draft
prompt and `SmartDraftNavigationGuard` to confirm leaving a changed form.

Encryption belongs at the storage boundary. Wrap any storage implementation
with application-provided authenticated encryption:

```dart
final secureDraftStorage = SmartTransformDraftStorage(
  storage: localStorage,
  encode: encryptDraft,
  decode: decryptDraft,
);
```

Sensitive values can be excluded directly on fields:

```dart
SmartPasswordField(
  name: 'password',
  excludeFromDraft: true,
);
```

Field-level exclusions are combined with the controller-level
`excludedFields` set.

When persistence belongs to your own architecture, adapt the package to your
controller or domain use case with `SmartCallbackDraftStorage`. This keeps
ObjectBox, repositories, and database entities inside the application instead
of leaking them into the widget layer:

```dart
final draftStorage = SmartCallbackDraftStorage(
  onRead: profileFormController.readDraftPayload,
  onWrite: profileFormController.saveDraftPayload,
  onDelete: profileFormController.deleteDraftPayload,
);

final draftController = SmartFormDraftController(
  id: 'edit-profile',
  storage: draftStorage,
  restoreAutomatically: true,
);
```

For example, `saveDraftPayload` can call a presentation controller, which calls
a domain use case, which writes the payload to an ObjectBox-backed repository.
The package only needs the string payload for a draft id.

`SmartMemoryDraftStorage` is included for tests and temporary in-process
drafts. Production applications should adapt durable platform storage and use
authenticated encryption when draft contents are sensitive.

## Submission

`SmartForm` can own the submit callback while `SmartSubmitButton` manages
validation, loading state, duplicate-tap prevention, and draft cleanup after a
successful submit:

```dart
final controller = SmartFormController();

SmartForm(
  controller: controller,
  draftController: draftController,
  onSubmit: (values) async {
    await repository.register(values);
  },
  children: [
    SmartEmailField(name: 'email', required: true),
    SmartPasswordField(
      name: 'password',
      required: true,
      excludeFromDraft: true,
    ),
    SmartSubmitButton(
      controller: controller,
      child: const Text('Create account'),
    ),
  ],
);
```

For custom buttons or menu actions, call `await controller.submit()`. The
controller exposes `isSubmitting`, `submissionError`, and `lastSubmitResult`.

## Conditional fields

Use `SmartConditionalField` when a field should exist only while another field
has a matching value. Hidden children are removed from registration, validation,
and form values:

```dart
SmartDropdownField<AccountType>(
  name: 'account_type',
  items: AccountType.values,
  itemLabelBuilder: (value) => value.name,
);

SmartConditionalField(
  dependsOn: 'account_type',
  condition: (value, _) => value == AccountType.business,
  duration: const Duration(milliseconds: 250),
  child: SmartTextField(
    name: 'company_name',
    validators: [SmartValidators.required()],
  ),
);
```

Conditional fields animate with a built-in fade and size transition by default.
Use `transitionBuilder` when the application needs a custom animation.

## Example application

The [example](example/) directory contains five Material 3 screens: a complete
registration flow, a form built entirely from view items, an API-model-class
form, a snake_case JSON/API form, and an imperative controller playground.
Together they demonstrate reusable and custom fields, sync/async validation,
item spacing, draft autosaving and restoration, navigation protection,
bottom-sheet selection, value updates, dynamic and disabled fields, reset,
server errors, focus/scroll commands, and first-error navigation.

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
with `SmartFormTheme`, and `SmartSchemaForm` can build the same fields from API
JSON or Dart definition classes. Cross-field sync and async validators use
explicit dependency metadata and read-only form snapshots. Bundled
validation-message localization is intentionally out of scope.
