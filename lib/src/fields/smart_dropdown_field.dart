import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_form_field.dart';

typedef SmartItemLabelBuilder<T> = String Function(T item);
typedef SmartDropdownItemBuilder<T> =
    Widget Function(BuildContext context, T item);

/// A Material dropdown connected to the closest [SmartForm].
class SmartDropdownField<T> extends StatefulWidget {
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
    this.autovalidateMode = AutovalidateMode.onUnfocus,
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

  final String name;
  final List<T> items;
  final SmartItemLabelBuilder<T> itemLabelBuilder;
  final SmartDropdownItemBuilder<T>? itemBuilder;
  final T? initialValue;
  final FocusNode? focusNode;
  final bool required;
  final String requiredMessage;
  final List<SmartValidator<T>> validators;
  final List<SmartAsyncValidator<T>> asyncValidators;
  final AutovalidateMode autovalidateMode;
  final SmartErrorAnimation? errorAnimation;
  final bool enabled;
  final InputDecoration decoration;
  final Widget? hint;
  final Widget? disabledHint;
  final bool isExpanded;
  final double? menuMaxHeight;
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
