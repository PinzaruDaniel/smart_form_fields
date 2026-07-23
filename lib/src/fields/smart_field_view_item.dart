import 'package:flutter/widgets.dart';

/// An immutable description that can build one field inside a [SmartForm].
abstract class SmartFieldViewItem {
  /// Creates a field view item registered under [name].
  const SmartFieldViewItem({required this.name})
    : assert(name.length > 0, 'A field item name cannot be empty.');

  /// Unique form field name represented by this item.
  final String name;

  /// Builds the field widget represented by this item.
  Widget build(BuildContext context);
}

/// A field item backed by an application-provided widget builder.
final class SmartWidgetFieldViewItem extends SmartFieldViewItem {
  /// Creates a custom field item.
  const SmartWidgetFieldViewItem({required super.name, required this.builder});

  /// Builds the application-owned field widget.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}
