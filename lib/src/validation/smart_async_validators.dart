import 'smart_async_validator.dart';
import 'smart_validation_context.dart';
import 'smart_validator_metadata.dart';

/// Factories for asynchronous validators that depend on other form fields.
abstract final class SmartAsyncValidators {
  /// Creates an async validator with explicit [dependsOn] metadata.
  ///
  /// Every field read from [SmartValidationContext] should appear in
  /// [dependsOn] so source changes can automatically revalidate this field.
  static SmartAsyncValidator<T> dependent<T>({
    required Iterable<String> dependsOn,
    required SmartContextAsyncValidator<T> validator,
  }) {
    return createDependentAsyncValidator<T>(
      dependsOn: dependsOn,
      validator: validator,
    );
  }
}
