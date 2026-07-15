import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_field_controller.dart';
import 'smart_form_field.dart';

typedef SmartDateFormatter =
    String Function(BuildContext context, DateTime value);

/// A date field backed by Flutter's Material date picker.
class SmartDateField extends StatefulWidget {
  const SmartDateField({
    required this.name,
    required this.firstDate,
    required this.lastDate,
    this.initialValue,
    this.currentDate,
    this.focusNode,
    this.required = false,
    this.requiredMessage = 'This field is required.',
    this.validators = const [],
    this.asyncValidators = const [],
    this.autovalidateMode,
    this.errorAnimation,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.selectableDayPredicate,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.initialDatePickerMode = DatePickerMode.day,
    this.locale,
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.dateFormatter,
    this.onChanged,
    super.key,
  });

  final String name;
  final DateTime? initialValue;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? currentDate;
  final FocusNode? focusNode;
  final bool required;
  final String requiredMessage;
  final List<SmartValidator<DateTime>> validators;
  final List<SmartAsyncValidator<DateTime>> asyncValidators;
  final AutovalidateMode? autovalidateMode;
  final SmartErrorAnimation? errorAnimation;
  final bool enabled;
  final InputDecoration decoration;
  final SelectableDayPredicate? selectableDayPredicate;
  final DatePickerEntryMode initialEntryMode;
  final DatePickerMode initialDatePickerMode;
  final Locale? locale;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;
  final SmartDateFormatter? dateFormatter;
  final ValueChanged<DateTime?>? onChanged;

  @override
  State<SmartDateField> createState() => _SmartDateFieldState();
}

class _SmartDateFieldState extends State<SmartDateField> {
  final TextEditingController _textController = TextEditingController();
  late List<SmartValidator<DateTime>> _validators;

  @override
  void initState() {
    super.initState();
    _rebuildValidators();
  }

  @override
  void didUpdateWidget(SmartDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.required != widget.required ||
        oldWidget.requiredMessage != widget.requiredMessage ||
        !identical(oldWidget.validators, widget.validators)) {
      _rebuildValidators();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _rebuildValidators() {
    _validators = <SmartValidator<DateTime>>[
      if (widget.required)
        SmartValidators.required<DateTime>(message: widget.requiredMessage),
      ...widget.validators,
    ];
  }

  String _formatDate(BuildContext context, DateTime value) {
    return widget.dateFormatter?.call(context, value) ??
        MaterialLocalizations.of(context).formatCompactDate(value);
  }

  void _syncText(BuildContext context, DateTime? value) {
    final text = value == null ? '' : _formatDate(context, value);
    if (_textController.text == text) {
      return;
    }
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  DateTime _pickerInitialDate(DateTime? value) {
    final firstDate = DateUtils.dateOnly(widget.firstDate);
    final lastDate = DateUtils.dateOnly(widget.lastDate);
    final candidate = DateUtils.dateOnly(
      value ?? widget.currentDate ?? DateTime.now(),
    );
    if (candidate.isBefore(firstDate)) {
      return firstDate;
    }
    if (candidate.isAfter(lastDate)) {
      return lastDate;
    }
    return candidate;
  }

  Future<void> _pickDate(
    BuildContext context,
    SmartFieldController<DateTime> field,
  ) async {
    if (!field.enabled) {
      return;
    }
    final selected = await showDatePicker(
      context: context,
      initialDate: _pickerInitialDate(field.value),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      currentDate: widget.currentDate,
      selectableDayPredicate: widget.selectableDayPredicate,
      initialEntryMode: widget.initialEntryMode,
      initialDatePickerMode: widget.initialDatePickerMode,
      locale: widget.locale,
      helpText: widget.helpText,
      cancelText: widget.cancelText,
      confirmText: widget.confirmText,
    );
    if (selected != null && mounted) {
      final value = DateUtils.dateOnly(selected);
      field.didChange(value);
      widget.onChanged?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartFormField<DateTime>(
      name: widget.name,
      initialValue: widget.initialValue == null
          ? null
          : DateUtils.dateOnly(widget.initialValue!),
      validators: _validators,
      asyncValidators: widget.asyncValidators,
      autovalidateMode: widget.autovalidateMode,
      errorAnimation: widget.errorAnimation,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      builder: (context, field) {
        _syncText(context, field.value);
        return TextField(
          controller: _textController,
          focusNode: field.focusNode,
          enabled: field.enabled,
          readOnly: true,
          decoration: widget.decoration.copyWith(
            errorText: field.errorText,
            suffixIcon:
                widget.decoration.suffixIcon ??
                const Icon(Icons.calendar_today_outlined),
          ),
          onTap: field.enabled ? () => _pickDate(context, field) : null,
        );
      },
    );
  }
}
