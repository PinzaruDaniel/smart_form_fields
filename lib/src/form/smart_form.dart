import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

import '../animation/smart_error_animation.dart';
import '../draft/smart_form_draft.dart';
import '../fields/smart_field_view_item.dart';
import '../theme/smart_form_theme.dart';
import '../validation/smart_validation_context.dart';
import 'smart_api_errors.dart';
import 'smart_field_handle.dart';
import 'smart_field_registry.dart';
import 'smart_form_controller.dart';
import 'smart_form_field_status.dart';
import 'smart_form_result.dart';
import 'smart_form_scope.dart';

/// Coordinates the smart fields below it.
class SmartForm extends StatefulWidget {
  /// Creates a form from [children] or declarative field [items].
  const SmartForm({
    this.children = const [],
    this.items = const [],
    this.itemSeparatorHeight = 0,
    this.controller,
    this.draftController,
    this.scrollToFirstError,
    this.focusFirstError,
    this.scrollDuration,
    this.scrollCurve,
    this.scrollAlignment,
    this.errorAnimation,
    this.dismissKeyboardOnTapOutside = true,
    this.unfocusOnKeyboardDismiss = true,
    this.onKeyboardVisibilityChanged,
    this.onSubmit,
    this.autovalidateMode = AutovalidateMode.onUnfocus,
    this.mainAxisSize = MainAxisSize.min,
    super.key,
  }) : assert(
         itemSeparatorHeight >= 0,
         'itemSeparatorHeight cannot be negative.',
       ),
       assert(
         draftController == null || controller != null,
         'A SmartForm with draftController also needs a controller.',
       );

  /// Fields and other widgets laid out vertically in registration order.
  final List<Widget> children;

  /// Declarative field items laid out vertically in their list order.
  final List<SmartFieldViewItem> items;

  /// Vertical space inserted between consecutive [items].
  final double itemSeparatorHeight;

  /// Optional controller for imperative access to this form.
  final SmartFormController? controller;

  /// Optional draft lifecycle attached to [controller] after the first frame.
  final SmartFormDraftController? draftController;

  /// Whether validation scrolls to the first invalid field.
  final bool? scrollToFirstError;

  /// Whether validation focuses the first invalid field.
  final bool? focusFirstError;

  /// Duration of first-error scrolling, or null to use the form theme.
  final Duration? scrollDuration;

  /// Curve used for first-error scrolling, or null to use the form theme.
  final Curve? scrollCurve;

  /// Alignment passed to `Scrollable.ensureVisible` during navigation.
  final double? scrollAlignment;

  /// Error animation for descendant fields, or null to use the form theme.
  final SmartErrorAnimation? errorAnimation;

  /// Unfocuses this form's active field when a pointer taps outside it.
  final bool dismissKeyboardOnTapOutside;

  /// Unfocuses this form's active field when the keyboard becomes hidden.
  final bool unfocusOnKeyboardDismiss;

  /// Called when the keyboard changes between visible and hidden.
  final ValueChanged<bool>? onKeyboardVisibilityChanged;

  /// Called by [SmartFormController.submit] after validation succeeds.
  ///
  /// When this callback completes successfully, an attached draft controller is
  /// marked submitted so its stored draft is cleared.
  final SmartFormSubmitCallback? onSubmit;

  /// Default automatic validation mode for descendant smart fields.
  ///
  /// A field can override this value with its own `autovalidateMode`.
  final AutovalidateMode autovalidateMode;

  /// Vertical sizing behavior of the form's internal column.
  final MainAxisSize mainAxisSize;

  @override
  SmartFormState createState() => SmartFormState();
}

/// Mutable state and imperative operations for a mounted [SmartForm].
class SmartFormState extends State<SmartForm>
    with WidgetsBindingObserver
    implements SmartFormControllerDelegate, SmartFormRegistrar {
  final SmartFieldRegistry _registry = SmartFieldRegistry();
  final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: 'SmartForm focus scope',
  );
  FlutterView? _view;
  double _lastKeyboardInset = 0;
  final Set<VoidCallback> _formListeners = <VoidCallback>{};
  bool _formNotificationScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?.attach(this);
    _attachDraftAfterLayout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextView = View.maybeOf(context);
    if (!identical(_view, nextView)) {
      _view = nextView;
      _lastKeyboardInset = nextView?.viewInsets.bottom ?? 0;
    }
  }

  @override
  void didChangeMetrics() {
    final currentInset = _view?.viewInsets.bottom ?? 0;
    final previousInset = _lastKeyboardInset;
    final wasVisible = previousInset > 0;
    final isVisible = currentInset > 0;
    _lastKeyboardInset = currentInset;

    if (wasVisible != isVisible) {
      widget.onKeyboardVisibilityChanged?.call(isVisible);
    }
    if (widget.unfocusOnKeyboardDismiss && wasVisible && !isVisible) {
      _unfocusForm();
    }
  }

  @override
  void didUpdateWidget(SmartForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      if (oldWidget.controller != null) {
        oldWidget.draftController?.detach(oldWidget.controller!);
      }
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
    if (!identical(oldWidget.draftController, widget.draftController) ||
        !identical(oldWidget.controller, widget.controller)) {
      if (identical(oldWidget.controller, widget.controller) &&
          oldWidget.controller != null) {
        oldWidget.draftController?.detach(oldWidget.controller!);
      }
      _attachDraftAfterLayout();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller != null) {
      widget.draftController?.detach(widget.controller!);
    }
    widget.controller?.detach(this);
    _focusScopeNode.dispose();
    super.dispose();
  }

  void _attachDraftAfterLayout() {
    final draft = widget.draftController;
    final controller = widget.controller;
    if (draft == null || controller == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          identical(widget.draftController, draft) &&
          identical(widget.controller, controller)) {
        unawaited(draft.attach(controller));
      }
    });
  }

  void _unfocusForm() {
    if (_focusScopeNode.hasFocus) {
      _focusScopeNode.unfocus();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.dismissKeyboardOnTapOutside || !_focusScopeNode.hasFocus) {
      return;
    }
    if (_registry.containsGlobalPosition(event.position)) {
      return;
    }
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final renderObject = focusContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) {
      _unfocusForm();
      return;
    }
    final localPosition = renderObject.globalToLocal(event.position);
    if (!renderObject.paintBounds.contains(localPosition)) {
      _unfocusForm();
    }
  }

  @override
  Map<String, Object?> get values =>
      Map<String, Object?>.unmodifiable(_registry.values);

  @override
  Map<String, SmartFormFieldStatus> get fieldStatuses =>
      Map<String, SmartFormFieldStatus>.unmodifiable(_registry.statuses);

  @override
  void addFormListener(VoidCallback listener) => _formListeners.add(listener);

  @override
  void removeFormListener(VoidCallback listener) =>
      _formListeners.remove(listener);

  void _notifyFormListeners() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_formNotificationScheduled) {
        return;
      }
      _formNotificationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formNotificationScheduled = false;
        if (mounted) {
          _dispatchFormListeners();
        }
      });
      return;
    }
    _dispatchFormListeners();
  }

  void _dispatchFormListeners() {
    for (final listener in List<VoidCallback>.of(_formListeners)) {
      listener();
    }
  }

  @override
  SmartValidationContext get validationContext {
    return SmartValidationContext(_registry.values);
  }

  @override
  T? valueOf<T>(String name) {
    final value = _fieldNamed(name).value;
    if (value == null) {
      return null;
    }
    if (value is! T) {
      throw StateError(
        'Field "$name" contains ${value.runtimeType}, not the requested type '
        '$T.',
      );
    }
    return value as T;
  }

  @override
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) async {
    final theme = SmartFormTheme.of(context);
    _registry.validateDependencyGraph(requireKnownFields: true);
    final fields = _registry.fields;
    final validationSnapshot = validationContext;
    for (final field in fields) {
      if (field.enabled) {
        await field.validate(animateError: false, context: validationSnapshot);
      }
    }

    final errors = <String, String>{
      for (final field in fields)
        if (field.enabled && !field.isValid && field.errorText != null)
          field.name: field.errorText!,
    };
    final firstInvalidField = _registry.firstInvalidField;
    final shouldScroll =
        scrollToError ?? widget.scrollToFirstError ?? theme.scrollToFirstError;
    final shouldFocus =
        focusFirstError ?? widget.focusFirstError ?? theme.focusFirstError;

    if (firstInvalidField != null) {
      await _navigateToInvalidField(
        firstInvalidField,
        scroll: shouldScroll,
        focus: shouldFocus,
      );
      if (mounted && _registry.contains(firstInvalidField)) {
        firstInvalidField.animateError();
      }
    }

    return SmartFormResult(
      isValid: firstInvalidField == null,
      values: await _registry.resolveResultValues(),
      errors: errors,
    );
  }

  @override
  Future<SmartFormResult> submit({
    bool? scrollToError,
    bool? focusFirstError,
  }) async {
    final result = await validate(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
    final onSubmit = widget.onSubmit;
    if (!result.isValid || onSubmit == null) {
      return result;
    }
    await onSubmit(result.values);
    await widget.draftController?.markSubmitted();
    return result;
  }

  Future<void> _navigateToInvalidField(
    SmartFieldHandle<Object?> field, {
    required bool scroll,
    required bool focus,
  }) async {
    if (!scroll && !focus) {
      return;
    }

    // Error widgets can change field heights. Navigate only after that layout
    // has completed, and tolerate a field disappearing during the frame.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_registry.contains(field)) {
      return;
    }

    if (scroll) {
      try {
        await field.scrollIntoView();
      } catch (_) {
        // Navigation is best-effort and must not alter the validation result.
      }
    }
    if (focus && mounted && _registry.contains(field)) {
      try {
        field.focus();
      } catch (_) {
        // A caller-owned focus node may become unavailable during navigation.
      }
    }
  }

  @override
  void setValue<T>(String name, T? value) {
    _fieldNamed(name).setValue(value);
  }

  @override
  void patchValue(Map<String, Object?> values) {
    final fields = <SmartFieldHandle<Object?>>[];
    for (final name in values.keys) {
      fields.add(_fieldNamed(name));
    }
    for (var index = 0; index < fields.length; index++) {
      fields[index].setValue(
        values.values.elementAt(index),
        notifyDependents: false,
      );
    }
    _revalidateDependents(values.keys);
    _notifyFormListeners();
  }

  @override
  void reset() {
    _registry.reset();
    _notifyFormListeners();
  }

  @override
  void clearErrors() => _registry.clearErrors();

  @override
  void setFieldError(String name, String error) {
    _fieldNamed(name).setError(error);
  }

  @override
  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) async {
    final fields = <SmartFieldHandle<Object?>>[];
    for (final name in errors.keys) {
      fields.add(_fieldNamed(name));
    }
    for (var index = 0; index < fields.length; index++) {
      fields[index].setError(
        errors.values.elementAt(index),
        animateError: !scrollToFirstError,
      );
    }
    if (scrollToFirstError) {
      final firstInvalidField = _registry.firstInvalidField;
      if (firstInvalidField != null) {
        await _navigateToInvalidField(
          firstInvalidField,
          scroll: true,
          focus: false,
        );
        if (mounted && _registry.contains(firstInvalidField)) {
          firstInvalidField.animateError();
        }
      }
    }
  }

  @override
  Future<SmartApiErrorResult> setErrorsFromResponse(
    Object? response, {
    SmartApiErrorExtractor? extractor,
    Map<String, String> fieldAliases = const {},
    String messageSeparator = '\n',
    bool clearExistingErrors = false,
    bool scrollToFirstError = false,
  }) async {
    if (messageSeparator.isEmpty) {
      throw ArgumentError.value(
        messageSeparator,
        'messageSeparator',
        'Must not be empty.',
      );
    }
    final payload = (extractor ?? SmartApiErrors.parse)(response);
    final appliedMessages = <String, List<String>>{};
    final unmappedErrors = <String, List<String>>{};

    for (final entry in payload.fieldErrors.entries) {
      final formFieldName = _matchApiFieldName(entry.key, fieldAliases);
      if (formFieldName == null) {
        unmappedErrors[entry.key] = entry.value;
        continue;
      }
      final messages = appliedMessages.putIfAbsent(
        formFieldName,
        () => <String>[],
      );
      for (final message in entry.value) {
        if (!messages.contains(message)) {
          messages.add(message);
        }
      }
    }

    final appliedErrors = <String, String>{
      for (final entry in appliedMessages.entries)
        entry.key: entry.value.join(messageSeparator),
    };
    if (clearExistingErrors) {
      clearErrors();
    }
    if (appliedErrors.isNotEmpty) {
      await setErrors(appliedErrors, scrollToFirstError: scrollToFirstError);
    }
    return SmartApiErrorResult(
      discoveredFieldErrors: payload.fieldErrors,
      appliedErrors: appliedErrors,
      unmappedFieldErrors: unmappedErrors,
      generalErrors: payload.generalErrors,
    );
  }

  String? _matchApiFieldName(String apiName, Map<String, String> fieldAliases) {
    final normalizedApiName = _normalizedFieldName(apiName);
    String? aliasedName = fieldAliases[apiName];
    if (aliasedName == null) {
      for (final entry in fieldAliases.entries) {
        if (_normalizedFieldName(entry.key) == normalizedApiName) {
          aliasedName = entry.value;
          break;
        }
      }
    }
    final candidate = aliasedName ?? apiName;
    if (_registry.fieldNamed(candidate) != null) {
      return candidate;
    }

    final normalizedCandidate = _normalizedFieldName(candidate);
    String? match;
    for (final field in _registry.fields) {
      if (_normalizedFieldName(field.name) == normalizedCandidate) {
        if (match != null) {
          return null;
        }
        match = field.name;
      }
    }
    return match;
  }

  String _normalizedFieldName(String name) {
    final segments = name
        .split(RegExp(r'[/\.\[\]]+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    final leaf = segments.isEmpty ? name : segments.last;
    return leaf.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
  }

  @override
  Future<void> focusField(String name) async {
    _fieldNamed(name).focus();
  }

  @override
  Future<void> scrollToField(String name) {
    return _fieldNamed(name).scrollIntoView();
  }

  @override
  void registerField(
    SmartFieldHandle<Object?> field, {
    required int sectionOrder,
  }) {
    _registry.register(field, sectionOrder: sectionOrder);
  }

  @override
  void unregisterField(SmartFieldHandle<Object?> field) {
    _registry.unregister(field);
  }

  @override
  void fieldValueChanged(SmartFieldHandle<Object?> field) {
    if (_registry.contains(field)) {
      _revalidateDependents(<String>[field.name]);
      _notifyFormListeners();
    }
  }

  @override
  void fieldStateChanged(SmartFieldHandle<Object?> field) {
    if (_registry.contains(field)) {
      _notifyFormListeners();
    }
  }

  void _revalidateDependents(Iterable<String> sourceNames) {
    _registry.validateDependencyGraph(requireKnownFields: false);
    final context = validationContext;
    for (final dependent in _registry.dependentsOf(sourceNames)) {
      dependent.dependencyDidChange(context);
    }
  }

  SmartFieldHandle<Object?> _fieldNamed(String name) {
    return _registry.fieldNamed(name) ??
        (throw ArgumentError.value(
          name,
          'name',
          'No field with this name is registered.',
        ));
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.children.isEmpty || widget.items.isEmpty,
      'Provide children or items, not both.',
    );
    final theme = SmartFormTheme.of(context);
    return TapRegion(
      onTapOutside: widget.dismissKeyboardOnTapOutside
          ? (_) => _unfocusForm()
          : null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        child: FocusScope(
          node: _focusScopeNode,
          child: SmartFormScope(
            registrar: this,
            scrollDuration: widget.scrollDuration ?? theme.scrollDuration,
            scrollCurve: widget.scrollCurve ?? theme.scrollCurve,
            scrollAlignment: widget.scrollAlignment ?? theme.scrollAlignment,
            errorAnimation: widget.errorAnimation ?? theme.errorAnimation,
            autovalidateMode: widget.autovalidateMode,
            child: Column(
              mainAxisSize: widget.mainAxisSize,
              children: _buildFormChildren(context),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormChildren(BuildContext context) {
    if (widget.items.isNotEmpty) {
      return <Widget>[
        for (var index = 0; index < widget.items.length; index++) ...<Widget>[
          if (index > 0) SizedBox(height: widget.itemSeparatorHeight),
          SmartFormOrderScope(
            key: ValueKey<String>(widget.items[index].name),
            order: index,
            child: widget.items[index].build(context),
          ),
        ],
      ];
    }

    return <Widget>[
      for (var index = 0; index < widget.children.length; index++)
        SmartFormOrderScope(
          key: widget.children[index].key == null
              ? null
              : ValueKey<Key>(widget.children[index].key!),
          order: index,
          child: widget.children[index],
        ),
    ];
  }
}
