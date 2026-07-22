import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../animation/smart_error_animation.dart';
import '../form/smart_field_handle.dart';
import '../form/smart_form_scope.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validation_context.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validator_metadata.dart';
import 'smart_field_controller.dart';

/// Builds a custom field from its public state controller.
typedef SmartFieldBuilder<T> =
    Widget Function(BuildContext context, SmartFieldController<T> field);

/// Converts a live field value into the value returned by form validation.
typedef SmartResultValueTransformer<T> = FutureOr<Object?> Function(T? value);

/// A generic field that participates in the closest [SmartForm].
class SmartFormField<T> extends StatefulWidget {
  /// Creates a custom field registered with the closest [SmartForm].
  const SmartFormField({
    required this.name,
    required this.builder,
    this.initialValue,
    this.validators = const [],
    this.asyncValidators = const [],
    this.enabled = true,
    this.focusNode,
    this.autovalidateMode,
    this.asyncValidationDebounce,
    this.errorAnimation,
    this.resultValueTransformer,
    super.key,
  }) : assert(name.length > 0, 'A field name cannot be empty.');

  /// Unique name used for registration, values, and errors.
  final String name;

  /// Value restored by [SmartFieldController.reset].
  final T? initialValue;

  /// Synchronous validators run in declaration order.
  final List<SmartValueValidator<T>> validators;

  /// Asynchronous validators run after synchronous validation succeeds.
  final List<SmartAsyncValidator<T>> asyncValidators;

  /// Builds the field's application-owned interface.
  final SmartFieldBuilder<T> builder;

  /// Whether the field accepts changes and participates in validation.
  final bool enabled;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Controls when validation runs without an explicit form validation call.
  ///
  /// When omitted, inherits the containing `SmartForm.autovalidateMode`.
  /// Explicit controller/key validation always runs immediately.
  final AutovalidateMode? autovalidateMode;

  /// Delay before asynchronous validators run after a value change.
  ///
  /// Explicit calls to [SmartFieldController.validate] and form validation
  /// always bypass this delay.
  final Duration? asyncValidationDebounce;

  /// Overrides the containing form's error animation for this field.
  final SmartErrorAnimation? errorAnimation;

  /// Optionally transforms the value captured in the validation result.
  ///
  /// Live controller values and validation contexts continue exposing [T].
  /// The transformer may perform asynchronous normalization for submission.
  final SmartResultValueTransformer<T>? resultValueTransformer;

  @override
  State<SmartFormField<T>> createState() => _SmartFormFieldState<T>();
}

class _SmartFormFieldState<T> extends State<SmartFormField<T>>
    with SingleTickerProviderStateMixin
    implements SmartFieldController<T>, SmartFieldHandle<T> {
  final GlobalKey _anchorKey = GlobalKey();

  SmartFormScope? _formScope;
  late FocusNode _focusNode;
  late T? _value;
  String? _errorText;
  bool _isValidating = false;
  bool _isDirty = false;
  bool _isTouched = false;
  bool _hasValidated = false;
  bool _wasFocused = false;
  int _validationGeneration = 0;
  late final AnimationController _errorAnimationController;
  bool _errorAnimationActive = false;

  @override
  String get name => widget.name;

  @override
  T? get value => _value;

  @override
  Future<Object?> resolveResultValue() async {
    final transformer = widget.resultValueTransformer;
    return transformer == null ? _value : await transformer(_value);
  }

  @override
  String? get errorText => _errorText;

  @override
  Set<String> get dependencies => dependenciesOfValidators(<Object>[
    ...widget.validators,
    ...widget.asyncValidators,
  ]);

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
    _wasFocused = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChanged);
    _errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final previousMode = _formScope == null ? null : _effectiveAutovalidateMode;
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
    if (previousMode == null &&
        widget.enabled &&
        _effectiveAutovalidateMode == AutovalidateMode.always) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_validateAutomatically(reason: 'automatically'));
        }
      });
    } else if (previousMode != null &&
        previousMode != _effectiveAutovalidateMode &&
        _shouldAutovalidateNow) {
      unawaited(
        _validateAutomatically(reason: 'after form validation mode changed'),
      );
    }
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
      final hadFocus = _focusNode.hasFocus;
      _focusNode.removeListener(_handleFocusChanged);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChanged);
      _wasFocused = _focusNode.hasFocus || hadFocus;
      if (hadFocus && widget.enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            focus();
          }
        });
      }
    }
    if (!_isDirty && oldWidget.initialValue != widget.initialValue) {
      _validationGeneration++;
      _value = widget.initialValue;
      _errorText = null;
      _isValidating = false;
      _hasValidated = false;
    }
    final validatorsChanged =
        !listEquals(oldWidget.validators, widget.validators) ||
        !listEquals(oldWidget.asyncValidators, widget.asyncValidators) ||
        oldWidget.asyncValidationDebounce != widget.asyncValidationDebounce;
    if (oldWidget.enabled != widget.enabled) {
      _validationGeneration++;
      _errorText = null;
      _isValidating = false;
      if (_shouldAutovalidateNow) {
        unawaited(_validateAutomatically(reason: 'after being enabled'));
      }
    } else if (validatorsChanged) {
      _validationGeneration++;
      _isValidating = false;
      if (_shouldAutovalidateNow) {
        unawaited(_validateAutomatically(reason: 'after validators changed'));
      }
    }
    final oldAutovalidateMode =
        oldWidget.autovalidateMode ??
        _formScope?.autovalidateMode ??
        AutovalidateMode.onUnfocus;
    if (oldAutovalidateMode != _effectiveAutovalidateMode &&
        _shouldAutovalidateNow) {
      unawaited(
        _validateAutomatically(reason: 'after validation mode changed'),
      );
    }
  }

  @override
  void dispose() {
    _validationGeneration++;
    _formScope?.registrar.unregisterField(this);
    _focusNode.removeListener(_handleFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _errorAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChange(T? value) => _changeValue(value, notifyDependents: true);

  void _changeValue(T? value, {required bool notifyDependents}) {
    final shouldRevalidateExistingError =
        _effectiveAutovalidateMode ==
            AutovalidateMode.onUserInteractionIfError &&
        _errorText != null;
    _validationGeneration++;
    setState(() {
      _value = value;
      _errorText = null;
      _isValidating = false;
      _isDirty = true;
      _isTouched = true;
    });
    if (notifyDependents) {
      _formScope?.registrar.fieldValueChanged(this);
    }
    if (widget.enabled &&
        (_effectiveAutovalidateMode == AutovalidateMode.always ||
            _effectiveAutovalidateMode == AutovalidateMode.onUserInteraction ||
            shouldRevalidateExistingError)) {
      unawaited(
        _validateAutomatically(
          debounceAsync: true,
          reason: 'after its value changed',
        ),
      );
    }
  }

  @override
  void setValue(T? value, {bool notifyDependents = true}) {
    _changeValue(value, notifyDependents: notifyDependents);
  }

  @override
  Future<bool> validate({
    bool animateError = true,
    SmartValidationContext? context,
  }) async {
    final generation = ++_validationGeneration;
    return _validateGeneration(
      generation,
      debounceAsync: false,
      animateError: animateError,
      context: context ?? _validationContext,
    );
  }

  @override
  void dependencyDidChange(SmartValidationContext context) {
    if (!widget.enabled || !_hasValidated) {
      return;
    }
    _validationGeneration++;
    unawaited(
      _validateAutomatically(
        debounceAsync: true,
        reason: 'after a dependency changed',
        context: context,
      ),
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _wasFocused = true;
      return;
    }
    if (!_wasFocused) {
      return;
    }
    _wasFocused = false;
    if (widget.enabled &&
        _effectiveAutovalidateMode == AutovalidateMode.onUnfocus) {
      unawaited(_validateAutomatically(reason: 'after losing focus'));
    }
  }

  Future<void> _validateAutomatically({
    bool debounceAsync = false,
    required String reason,
    SmartValidationContext? context,
  }) async {
    final generation = _validationGeneration;
    try {
      await _validateGeneration(
        generation,
        debounceAsync: debounceAsync,
        animateError: true,
        context: context ?? _validationContext,
      );
    } catch (error, stackTrace) {
      if (_isCurrentGeneration(generation)) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'smart_form_fields',
            context: ErrorDescription(
              'while asynchronously validating SmartFormField "$name" '
              '$reason',
            ),
          ),
        );
      }
    }
  }

  Future<bool> _validateGeneration(
    int generation, {
    required bool debounceAsync,
    required bool animateError,
    required SmartValidationContext context,
  }) async {
    final value = _value;

    if (_isCurrentGeneration(generation)) {
      setState(() {
        _isTouched = true;
        _isValidating = false;
        _hasValidated = true;
      });
    }

    try {
      for (final validator in widget.validators) {
        final error = runSmartValidator(validator, value, context);
        if (error != null) {
          _applyValidationResult(generation, error, animateError: animateError);
          return false;
        }
      }

      if (widget.asyncValidators.isNotEmpty &&
          _isCurrentGeneration(generation)) {
        setState(() => _isValidating = true);
      }

      final debounce = widget.asyncValidationDebounce;
      if (debounceAsync &&
          widget.asyncValidators.isNotEmpty &&
          debounce != null &&
          debounce > Duration.zero) {
        await Future<void>.delayed(debounce);
        if (!_isCurrentGeneration(generation)) {
          return isValid;
        }
      }

      for (final validator in widget.asyncValidators) {
        final error = await runSmartAsyncValidator(validator, value, context);
        if (!_isCurrentGeneration(generation)) {
          return isValid;
        }
        if (error != null) {
          _applyValidationResult(generation, error, animateError: animateError);
          return false;
        }
      }

      _applyValidationResult(generation, null, animateError: false);
      return true;
    } catch (_) {
      if (_isCurrentGeneration(generation)) {
        setState(() => _isValidating = false);
      }
      rethrow;
    }
  }

  void _applyValidationResult(
    int generation,
    String? error, {
    required bool animateError,
  }) {
    if (!_isCurrentGeneration(generation)) {
      return;
    }
    setState(() {
      _errorText = error;
      _isValidating = false;
    });
    if (error != null && animateError) {
      _animateError();
    }
  }

  bool _isCurrentGeneration(int generation) {
    return mounted && generation == _validationGeneration;
  }

  bool get _shouldAutovalidateNow {
    if (!widget.enabled) {
      return false;
    }
    return switch (_effectiveAutovalidateMode) {
      AutovalidateMode.disabled => false,
      AutovalidateMode.always => true,
      AutovalidateMode.onUserInteraction => _isDirty,
      AutovalidateMode.onUnfocus => _isTouched && !_focusNode.hasFocus,
      AutovalidateMode.onUserInteractionIfError =>
        _isDirty && _errorText != null,
    };
  }

  AutovalidateMode get _effectiveAutovalidateMode {
    return widget.autovalidateMode ??
        _formScope?.autovalidateMode ??
        AutovalidateMode.onUnfocus;
  }

  SmartValidationContext get _validationContext {
    return _formScope?.registrar.validationContext ??
        SmartValidationContext(<String, Object?>{name: _value});
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
      _hasValidated = false;
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
  void setError(String error, {bool animateError = true}) {
    _validationGeneration++;
    setState(() {
      _errorText = error;
      _isValidating = false;
      _isTouched = true;
      _hasValidated = true;
    });
    if (animateError) {
      _animateError();
    }
  }

  @override
  void animateError() => _animateError();

  SmartErrorAnimation get _effectiveErrorAnimation {
    return widget.errorAnimation ??
        _formScope?.errorAnimation ??
        SmartErrorAnimation.none;
  }

  void _animateError() {
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (animationsDisabled ||
        _effectiveErrorAnimation == SmartErrorAnimation.none) {
      _errorAnimationActive = false;
      _errorAnimationController.value = 1;
      return;
    }
    _errorAnimationActive = true;
    unawaited(_errorAnimationController.forward(from: 0));
  }

  @override
  void focus() {
    if (widget.enabled && _focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  bool containsGlobalPosition(Offset position) {
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) {
      return false;
    }
    final localPosition = renderObject.globalToLocal(position);
    return renderObject.paintBounds.contains(localPosition);
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
      builder: (context) {
        final child = widget.builder(context, this);
        return AnimatedBuilder(
          animation: _errorAnimationController,
          child: child,
          builder: (context, child) {
            if (!_errorAnimationActive) {
              return child!;
            }
            final progress = Curves.easeOut.transform(
              _errorAnimationController.value,
            );
            return switch (_effectiveErrorAnimation) {
              SmartErrorAnimation.none => child!,
              SmartErrorAnimation.shake => Transform.translate(
                offset: Offset(
                  math.sin(progress * math.pi * 6) * 8 * (1 - progress),
                  0,
                ),
                child: child,
              ),
              SmartErrorAnimation.fade => Opacity(
                opacity: 0.45 + 0.55 * progress,
                child: child,
              ),
            };
          },
        );
      },
    );
  }
}
