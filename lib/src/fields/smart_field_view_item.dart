import 'package:flutter/widgets.dart';

/// Reads the current value represented by a [SmartFieldViewItem].
typedef SmartFieldValueReader = Object? Function();

/// An immutable description that can build one field inside a [SmartForm].
abstract class SmartFieldViewItem {
  /// Creates a field view item registered under [name].
  const SmartFieldViewItem({required this.name, this.valueReader})
    : assert(name.length > 0, 'A field item name cannot be empty.');

  /// Unique form field name represented by this item.
  final String name;

  /// Optional callback used by application-owned items to expose their value.
  ///
  /// Built-in item types override [value] when they own the field state.
  final SmartFieldValueReader? valueReader;

  /// Current value represented by this item, when available.
  Object? get value => valueReader?.call();

  /// Returns [value] as [T], or null when no value is available.
  ///
  /// Throws a [StateError] when a non-null value does not have the requested
  /// type.
  T? valueAs<T>() {
    final currentValue = value;
    if (currentValue == null) {
      return null;
    }
    if (currentValue is! T) {
      throw StateError(
        'Field item "$name" contains ${currentValue.runtimeType}, not the '
        'requested type $T.',
      );
    }
    return currentValue as T;
  }

  /// Current value as text, or an empty string when no value is available.
  String get text => maybeText ?? '';

  /// Current value as nullable text.
  String? get maybeText {
    final currentValue = value;
    if (currentValue == null) {
      return null;
    }
    if (currentValue is String) {
      return currentValue;
    }
    return currentValue.toString();
  }

  /// Builds the field widget represented by this item.
  Widget build(BuildContext context);
}

/// A field item backed by an application-provided widget builder.
final class SmartWidgetFieldViewItem extends SmartFieldViewItem {
  /// Creates a custom field item.
  const SmartWidgetFieldViewItem({
    required super.name,
    required this.builder,
    super.valueReader,
  });

  /// Builds the application-owned field widget.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}
