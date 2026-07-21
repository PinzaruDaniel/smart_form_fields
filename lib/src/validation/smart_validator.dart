/// A synchronous validator for the package's string-based fields.
///
/// Return an error message when [value] is invalid or `null` when it is valid.
typedef SmartValidator = SmartValueValidator<String>;

/// A synchronous validator for a field containing values of type [T].
///
/// Most text, email, phone, and password fields should use [SmartValidator].
/// Use this generic form for dates, typed dropdowns, and custom fields.
typedef SmartValueValidator<T> = String? Function(T? value);
