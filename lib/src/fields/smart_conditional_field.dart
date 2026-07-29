import 'package:flutter/widgets.dart';

import '../form/smart_form_scope.dart';
import '../validation/smart_validation_context.dart';

/// Decides whether a conditional field should be visible.
typedef SmartConditionalFieldCondition =
    bool Function(Object? value, SmartValidationContext context);

/// Shows [child] only when another field value satisfies [condition].
class SmartConditionalField extends StatefulWidget {
  /// Creates a field wrapper controlled by [dependsOn].
  const SmartConditionalField({
    required this.dependsOn,
    required this.condition,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
    super.key,
  });

  /// Source field name observed for visibility changes.
  final String dependsOn;

  /// Predicate evaluated with the source value and current form values.
  final SmartConditionalFieldCondition condition;

  /// Widget displayed when [condition] returns true.
  final Widget child;

  /// Widget displayed when [condition] returns false.
  final Widget placeholder;

  @override
  State<SmartConditionalField> createState() => _SmartConditionalFieldState();
}

class _SmartConditionalFieldState extends State<SmartConditionalField> {
  SmartFormScope? _scope;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScope = SmartFormScope.of(context);
    if (!identical(_scope?.registrar, nextScope.registrar)) {
      _scope?.registrar.removeFormListener(_handleFormChanged);
      _scope = nextScope;
      nextScope.registrar.addFormListener(_handleFormChanged);
    } else {
      _scope = nextScope;
    }
    _visible = _evaluate();
  }

  @override
  void didUpdateWidget(SmartConditionalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependsOn != widget.dependsOn ||
        !identical(oldWidget.condition, widget.condition)) {
      final visible = _evaluate();
      if (visible != _visible) {
        setState(() => _visible = visible);
      } else {
        _visible = visible;
      }
    }
  }

  @override
  void dispose() {
    _scope?.registrar.removeFormListener(_handleFormChanged);
    super.dispose();
  }

  void _handleFormChanged() {
    final visible = _evaluate();
    if (visible != _visible && mounted) {
      setState(() => _visible = visible);
    }
  }

  bool _evaluate() {
    final context = _scope?.registrar.validationContext;
    if (context == null) {
      return false;
    }
    return widget.condition(context.values[widget.dependsOn], context);
  }

  @override
  Widget build(BuildContext context) {
    return _visible ? widget.child : widget.placeholder;
  }
}
