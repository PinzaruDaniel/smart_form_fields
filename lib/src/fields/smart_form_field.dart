import 'package:flutter/widgets.dart';

import '../form/smart_field_handle.dart';
import '../form/smart_form_scope.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import 'smart_field_controller.dart';

typedef SmartFieldBuilder<T> =
    Widget Function(BuildContext context, SmartFieldController<T> field);

/// A generic field that participates in the closest [SmartForm].
class SmartFormField<T> extends StatefulWidget {
  const SmartFormField({
    required this.name,
    required this.builder,
    this.initialValue,
    this.validators = const [],
    this.asyncValidators = const [],
    this.enabled = true,
    this.focusNode,
    super.key,
  }) : assert(name.length > 0, 'A field name cannot be empty.');

  final String name;
  final T? initialValue;
  final List<SmartValidator<T>> validators;
  final List<SmartAsyncValidator<T>> asyncValidators;
  final SmartFieldBuilder<T> builder;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<SmartFormField<T>> createState() => _SmartFormFieldState<T>();
}

class _SmartFormFieldState<T> extends State<SmartFormField<T>>
    implements SmartFieldController<T>, SmartFieldHandle<T> {
  final GlobalKey _anchorKey = GlobalKey();

  SmartFormScope? _formScope;
  late FocusNode _focusNode;
  late T? _value;
  String? _errorText;
  bool _isValidating = false;
  bool _isDirty = false;
  bool _isTouched = false;
  int _validationGeneration = 0;

  @override
  String get name => widget.name;

  @override
  T? get value => _value;

  @override
  String? get errorText => _errorText;

  @override
  bool get enabled => widget.enabled;

  @override
  bool get isValid => _errorText == null;

  @override
  bool get isValidating => _isValidating;

  @override
  bool get isDirty => _isDirty;

  @override
  bool get isTouched => _isTouched;

  @override
  FocusNode get focusNode => _focusNode;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScope = SmartFormScope.of(context);
    if (!identical(_formScope?.registrar, nextScope.registrar)) {
      _formScope?.registrar.unregisterField(this);
      _formScope = nextScope;
    } else {
      _formScope = nextScope;
    }
    nextScope.registrar.registerField(
      this,
      sectionOrder: SmartFormOrderScope.of(context),
    );
  }

  @override
  void didUpdateWidget(SmartFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _formScope?.registrar.unregisterField(this);
      _formScope?.registrar.registerField(
        this,
        sectionOrder: SmartFormOrderScope.of(context),
      );
    }
    if (!identical(oldWidget.focusNode, widget.focusNode)) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (!_isDirty && oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
    if (!widget.enabled && oldWidget.enabled) {
      _validationGeneration++;
      _isValidating = false;
    }
  }

  @override
  void dispose() {
    _validationGeneration++;
    _formScope?.registrar.unregisterField(this);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didChange(T? value) {
    _validationGeneration++;
    setState(() {
      _value = value;
      _errorText = null;
      _isValidating = false;
      _isDirty = true;
      _isTouched = true;
    });
  }

  @override
  void setValue(T? value) => didChange(value);

  @override
  Future<bool> validate() async {
    final generation = ++_validationGeneration;
    setState(() {
      _isTouched = true;
      _isValidating = widget.asyncValidators.isNotEmpty;
    });

    try {
      for (final validator in widget.validators) {
        final error = validator(_value);
        if (error != null) {
          _applyValidationResult(generation, error);
          return false;
        }
      }

      for (final validator in widget.asyncValidators) {
        final error = await validator(_value);
        if (!_isCurrentGeneration(generation)) {
          return isValid;
        }
        if (error != null) {
          _applyValidationResult(generation, error);
          return false;
        }
      }

      _applyValidationResult(generation, null);
      return true;
    } catch (_) {
      if (_isCurrentGeneration(generation)) {
        setState(() => _isValidating = false);
      }
      rethrow;
    }
  }

  void _applyValidationResult(int generation, String? error) {
    if (!_isCurrentGeneration(generation)) {
      return;
    }
    setState(() {
      _errorText = error;
      _isValidating = false;
    });
  }

  bool _isCurrentGeneration(int generation) {
    return mounted && generation == _validationGeneration;
  }

  @override
  void reset() {
    _validationGeneration++;
    setState(() {
      _value = widget.initialValue;
      _errorText = null;
      _isValidating = false;
      _isDirty = false;
      _isTouched = false;
    });
  }

  @override
  void clearError() {
    _validationGeneration++;
    setState(() {
      _errorText = null;
      _isValidating = false;
    });
  }

  @override
  void setError(String error) {
    _validationGeneration++;
    setState(() {
      _errorText = error;
      _isValidating = false;
      _isTouched = true;
    });
  }

  @override
  void focus() {
    if (widget.enabled && _focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Future<void> scrollIntoView() async {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) {
      return;
    }
    final scope = _formScope!;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    await Scrollable.ensureVisible(
      anchorContext,
      duration: disableAnimations ? Duration.zero : scope.scrollDuration,
      curve: scope.scrollCurve,
      alignment: scope.scrollAlignment,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      key: _anchorKey,
      builder: (context) => widget.builder(context, this),
    );
  }
}
