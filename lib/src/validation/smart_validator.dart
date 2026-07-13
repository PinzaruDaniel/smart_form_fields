/// A synchronous validation function.
///
/// Return an error message when [value] is invalid or `null` when it is valid.
typedef SmartValidator<T> = String? Function(T? value);
