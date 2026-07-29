import 'package:flutter/material.dart';

import 'smart_form_controller.dart';

/// A Material submit button connected to a [SmartFormController].
class SmartSubmitButton extends StatelessWidget {
  /// Creates a submit button that validates and submits [controller].
  const SmartSubmitButton({
    required this.controller,
    required this.child,
    this.loadingChild,
    this.enabled = true,
    this.scrollToError,
    this.focusFirstError,
    this.onSubmitted,
    this.onError,
    this.style,
    super.key,
  });

  /// Controller attached to the target [SmartForm].
  final SmartFormController controller;

  /// Button content displayed while the form is not submitting.
  final Widget child;

  /// Button content displayed while a submission is running.
  final Widget? loadingChild;

  /// Whether the button can start a submission.
  final bool enabled;

  /// Overrides first-error scrolling for this submit action.
  final bool? scrollToError;

  /// Overrides first-error focusing for this submit action.
  final bool? focusFirstError;

  /// Called after a valid submission finishes successfully.
  final VoidCallback? onSubmitted;

  /// Called when `SmartForm.onSubmit` throws.
  final ValueChanged<Object>? onError;

  /// Optional style for the underlying [FilledButton].
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isSubmitting = controller.isSubmitting;
        return FilledButton(
          style: style,
          onPressed: enabled && !isSubmitting ? _submit : null,
          child: isSubmitting
              ? loadingChild ?? const _SmartSubmitButtonLoadingChild()
              : child,
        );
      },
    );
  }

  Future<void> _submit() async {
    try {
      final result = await controller.submit(
        scrollToError: scrollToError,
        focusFirstError: focusFirstError,
      );
      if (result.isValid) {
        onSubmitted?.call();
      }
    } catch (error) {
      onError?.call(error);
    }
  }
}

class _SmartSubmitButtonLoadingChild extends StatelessWidget {
  const _SmartSubmitButtonLoadingChild();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
