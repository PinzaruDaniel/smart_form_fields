## 0.0.11

* Start first-invalid-field error animation only after scrolling and focus
  navigation complete.
* Apply the same ordering when scrolling to injected server errors.
* Keep automatic field validation animations immediate when no navigation is
  requested.

## 0.0.10

* Add a form-level `autovalidateMode` default to `SmartForm` and
  `SmartJsonForm`.
* Let descendant fields inherit the form mode while preserving field-level
  overrides.
* Support submit-only validation without repeating configuration on every
  field.

## 0.0.9

* Preserve direct focus transfer when tapping another field in the same form.
* Treat only a fully hidden keyboard as dismissal so keyboard-height changes
  between input types do not unfocus the destination field.
* Prevent valid values from receiving transient required errors during field
  navigation.

## 0.0.8

* Unfocus the active form field when the keyboard becomes hidden.
* Dismiss focus when tapping outside the active field, including blank space
  inside the form.
* Add opt-out flags and a keyboard visibility callback on `SmartForm`.

## 0.0.7

* Split the example bootstrap, app shell, and screens into focused files.
* Add separate registration, JSON/API form, and controller playground screens.
* Demonstrate reusable and custom fields, JSON registries, bottom-sheet input,
  dynamic/disabled fields, and the complete key/controller command surface.

## 0.0.6

* Add `SmartFormSchema` and `SmartJsonForm.fromJson` for API-driven forms.
* Support built-in text, email, phone, password, date, and dropdown JSON field
  types with synchronous validator configuration.
* Allow applications to register custom JSON field builders, custom validator
  builders, and named asynchronous validators.
* Use snake_case keys throughout the API-driven JSON form schema.
* Document canonical keys such as `scroll_to_first_error`, `label_text`,
  `initial_value`, and `async_validators`.

## 0.0.5

* Complete the README guidance for installation, controller lifecycle, custom
  fields, async validation, server errors, disabled fields, and navigation.
* Demonstrate shared `SmartFormTheme` behavior in the example application.
* Align the implementation plan and public API documentation with
  application-owned validation localization.

## 0.0.4

* Add `SmartFormTheme` and `SmartFormThemeData` for shared scrolling, focus,
  and error-animation behavior.
* Allow values set directly on `SmartForm` to override inherited defaults.
* Keep validation-message localization application-owned without adding
  bundled language catalogs.

## 0.0.3

* Add reusable email, password, phone, date, and generic dropdown fields.
* Expand the registration example with birth-date and country fields.
* Add focused widget coverage for every reusable field and date-picker
  interaction.

## 0.0.2

* Validate fields on focus loss by default.
* Keep explicit form submission validation immediate and support opt-in
  change-time validation with `AutovalidateMode.onUserInteraction`.
* Prevent parent rebuilds from validating an `onUnfocus` field while it remains
  focused.
* Expand the example and widget tests for focus-loss and submission validation.

## 0.0.1

* Scaffold the Flutter package.
* Add `SmartForm`, `SmartFormKey`, and `SmartFormController` foundations.
* Add immutable `SmartFormResult` snapshots.
* Add lifecycle-safe field registration with duplicate-name detection,
  dynamic removal, nested-form isolation, and visual-order updates.
* Add generic and text fields with race-safe synchronous and asynchronous
  validation.
* Add built-in required, email, length, pattern, number, minimum, and maximum
  validators.
* Add configurable shake, fade, or disabled error animations with reduced
  motion support.
* Harden first-error scrolling and focus for nested scrollables, disappearing
  fields, and navigation failures.
