/// An asynchronous validation function.
///
/// Return an error message when [value] is invalid or `null` when it is valid.
typedef SmartAsyncValidator<T> = Future<String?> Function(T? value);
