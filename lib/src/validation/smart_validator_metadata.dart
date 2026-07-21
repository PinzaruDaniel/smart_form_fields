// ignore_for_file: public_member_api_docs

import 'smart_async_validator.dart';
import 'smart_validation_context.dart';
import 'smart_validator.dart';

typedef _SyncRunner =
    String? Function(Object? value, SmartValidationContext context);
typedef _AsyncRunner =
    Future<String?> Function(Object? value, SmartValidationContext context);

final class _SyncMetadata {
  const _SyncMetadata(this.dependencies, this.run);

  final Set<String> dependencies;
  final _SyncRunner run;
}

final class _AsyncMetadata {
  const _AsyncMetadata(this.dependencies, this.run);

  final Set<String> dependencies;
  final _AsyncRunner run;
}

final Expando<_SyncMetadata> _syncMetadata = Expando<_SyncMetadata>();
final Expando<_AsyncMetadata> _asyncMetadata = Expando<_AsyncMetadata>();

SmartValueValidator<T> createDependentValidator<T>({
  required Iterable<String> dependsOn,
  required SmartContextValidator<T> validator,
}) {
  final dependencies = _checkedDependencies(dependsOn);
  String? placeholder(T? value) {
    throw StateError(
      'A dependent validator must run through SmartFormField validation so '
      'that a SmartValidationContext is available.',
    );
  }

  _syncMetadata[placeholder] = _SyncMetadata(
    dependencies,
    (value, context) => validator(value as T?, context),
  );
  return placeholder;
}

SmartAsyncValidator<T> createDependentAsyncValidator<T>({
  required Iterable<String> dependsOn,
  required SmartContextAsyncValidator<T> validator,
}) {
  final dependencies = _checkedDependencies(dependsOn);
  Future<String?> placeholder(T? value) {
    throw StateError(
      'A dependent async validator must run through SmartFormField validation '
      'so that a SmartValidationContext is available.',
    );
  }

  _asyncMetadata[placeholder] = _AsyncMetadata(
    dependencies,
    (value, context) => validator(value as T?, context),
  );
  return placeholder;
}

Set<String> dependenciesOfValidators(Iterable<Object> validators) {
  return Set<String>.unmodifiable(<String>{
    for (final validator in validators)
      ...?_syncMetadata[validator]?.dependencies,
    for (final validator in validators)
      ...?_asyncMetadata[validator]?.dependencies,
  });
}

String? runSmartValidator<T>(
  SmartValueValidator<T> validator,
  T? value,
  SmartValidationContext context,
) {
  final metadata = _syncMetadata[validator];
  return metadata == null ? validator(value) : metadata.run(value, context);
}

Future<String?> runSmartAsyncValidator<T>(
  SmartAsyncValidator<T> validator,
  T? value,
  SmartValidationContext context,
) {
  final metadata = _asyncMetadata[validator];
  return metadata == null ? validator(value) : metadata.run(value, context);
}

SmartValueValidator<T> adaptSmartValidator<T>(
  SmartValueValidator<Object?> validator,
) {
  final metadata = _syncMetadata[validator];
  if (metadata == null) {
    return (value) => validator(value);
  }
  return createDependentValidator<T>(
    dependsOn: metadata.dependencies,
    validator: (value, context) => metadata.run(value, context),
  );
}

SmartAsyncValidator<T> adaptSmartAsyncValidator<T>(
  SmartAsyncValidator<Object?> validator,
) {
  final metadata = _asyncMetadata[validator];
  if (metadata == null) {
    return (value) => validator(value);
  }
  return createDependentAsyncValidator<T>(
    dependsOn: metadata.dependencies,
    validator: (value, context) => metadata.run(value, context),
  );
}

Set<String> dependenciesOfAsyncValidator(Object validator) {
  return _asyncMetadata[validator]?.dependencies ?? const <String>{};
}

Set<String> _checkedDependencies(Iterable<String> values) {
  final result = <String>{};
  for (final value in values) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'dependsOn', 'Names cannot be empty.');
    }
    result.add(value);
  }
  if (result.isEmpty) {
    throw ArgumentError.value(
      values,
      'dependsOn',
      'At least one dependency is required.',
    );
  }
  return Set<String>.unmodifiable(result);
}
