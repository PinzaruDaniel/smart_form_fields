import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_form_field.dart';

/// Produces the fallback text label for a dropdown item.
typedef SmartItemLabelBuilder<T> = String Function(T item);

/// Builds the widget displayed for a dropdown item.
typedef SmartDropdownItemBuilder<T> =
    Widget Function(BuildContext context, T item);

/// A Material dropdown connected to the closest [SmartForm].
class SmartDropdownField<T> extends StatefulWidget {
  /// Creates a Material dropdown registered as [name].
  const SmartDropdownField({
    required this.name,
    required this.items,
    required this.itemLabelBuilder,
    this.itemBuilder,
    this.initialValue,
    this.focusNode,
    this.required = false,
    this.requiredMessage = 'This field is required.',
    this.validators = const [],
    this.asyncValidators = const [],
    this.autovalidateMode,
    this.errorAnimation,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.hint,
    this.disabledHint,
    this.isExpanded = true,
    this.menuMaxHeight,
    this.onChanged,
    super.key,
  });

  /// Unique form field name.
  final String name;

  /// Values available for selection.
  final List<T> items;

  /// Produces a text label for each item and selected value.
  final SmartItemLabelBuilder<T> itemLabelBuilder;

  /// Optional custom widget builder for menu items.
  final SmartDropdownItemBuilder<T>? itemBuilder;

  /// Initial selected value.
  final T? initialValue;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Whether a null selection is invalid.
  final bool required;

  /// Message returned when [required] validation fails.
  final String requiredMessage;

  /// Additional synchronous validators run after required validation.
  final List<SmartValidator<T>> validators;

  /// Asynchronous validators run after synchronous validators pass.
  final List<SmartAsyncValidator<T>> asyncValidators;

  /// Field-level automatic validation override.
  final AutovalidateMode? autovalidateMode;

  /// Field-level error animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Whether the dropdown accepts input and participates in validation.
  final bool enabled;

  /// Material input decoration.
  final InputDecoration decoration;

  /// Widget displayed when there is no selection.
  final Widget? hint;

  /// Widget displayed when a disabled dropdown has no selection.
  final Widget? disabledHint;

  /// Whether the dropdown fills its available horizontal space.
  final bool isExpanded;

  /// Maximum height of the dropdown menu.
  final double? menuMaxHeight;

  /// Called whenever the selected value changes.
  final ValueChanged<T?>? onChanged;

  @override
  State<SmartDropdownField<T>> createState() => _SmartDropdownFieldState<T>();
}

class _SmartDropdownFieldState<T> extends State<SmartDropdownField<T>> {
  late List<SmartValidator<T>> _validators;

  @override
  void initState() {
    super.initState();
    _rebuildValidators();
  }

  @override
  void didUpdateWidget(SmartDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.required != widget.required ||
        oldWidget.requiredMessage != widget.requiredMessage ||
        !identical(oldWidget.validators, widget.validators)) {
      _rebuildValidators();
    }
  }

  void _rebuildValidators() {
    _validators = <SmartValidator<T>>[
      if (widget.required)
        SmartValidators.required<T>(message: widget.requiredMessage),
      ...widget.validators,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SmartFormField<T>(
      name: widget.name,
      initialValue: widget.initialValue,
      validators: _validators,
      asyncValidators: widget.asyncValidators,
      autovalidateMode: widget.autovalidateMode,
      errorAnimation: widget.errorAnimation,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      builder: (context, field) {
        return DropdownButtonFormField<T>(
          key: ValueKey<Object?>(field.value),
          initialValue: field.value,
          focusNode: field.focusNode,
          decoration: widget.decoration.copyWith(errorText: field.errorText),
          items: <DropdownMenuItem<T>>[
            for (final item in widget.items)
              DropdownMenuItem<T>(
                value: item,
                child:
                    widget.itemBuilder?.call(context, item) ??
                    Text(widget.itemLabelBuilder(item)),
              ),
          ],
          hint: widget.hint,
          disabledHint: widget.disabledHint,
          isExpanded: widget.isExpanded,
          menuMaxHeight: widget.menuMaxHeight,
          onChanged: field.enabled
              ? (value) {
                  field.didChange(value);
                  widget.onChanged?.call(value);
                }
              : null,
        );
      },
    );
  }
}
