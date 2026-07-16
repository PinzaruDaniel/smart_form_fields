import 'package:flutter/widgets.dart';

import '../animation/smart_error_animation.dart';

/// Behavior defaults for descendant `SmartForm` widgets.
@immutable
class SmartFormThemeData {
  /// Creates behavior defaults for descendant smart forms.
  const SmartFormThemeData({
    this.scrollToFirstError = true,
    this.focusFirstError = true,
    this.scrollDuration = const Duration(milliseconds: 350),
    this.scrollCurve = Curves.easeOutCubic,
    this.scrollAlignment = 0.2,
    this.errorAnimation = SmartErrorAnimation.shake,
  });

  /// Whether forms scroll to their first invalid field by default.
  final bool scrollToFirstError;

  /// Whether forms focus their first invalid field by default.
  final bool focusFirstError;

  /// Default duration for animated first-error scrolling.
  final Duration scrollDuration;

  /// Default curve for animated first-error scrolling.
  final Curve scrollCurve;

  /// Default alignment used when revealing an invalid field.
  final double scrollAlignment;

  /// Default animation applied when a field receives an error.
  final SmartErrorAnimation errorAnimation;

  /// Returns a copy with the supplied behavior defaults replaced.
  SmartFormThemeData copyWith({
    bool? scrollToFirstError,
    bool? focusFirstError,
    Duration? scrollDuration,
    Curve? scrollCurve,
    double? scrollAlignment,
    SmartErrorAnimation? errorAnimation,
  }) {
    return SmartFormThemeData(
      scrollToFirstError: scrollToFirstError ?? this.scrollToFirstError,
      focusFirstError: focusFirstError ?? this.focusFirstError,
      scrollDuration: scrollDuration ?? this.scrollDuration,
      scrollCurve: scrollCurve ?? this.scrollCurve,
      scrollAlignment: scrollAlignment ?? this.scrollAlignment,
      errorAnimation: errorAnimation ?? this.errorAnimation,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartFormThemeData &&
            other.scrollToFirstError == scrollToFirstError &&
            other.focusFirstError == focusFirstError &&
            other.scrollDuration == scrollDuration &&
            other.scrollCurve == scrollCurve &&
            other.scrollAlignment == scrollAlignment &&
            other.errorAnimation == errorAnimation;
  }

  @override
  int get hashCode => Object.hash(
    scrollToFirstError,
    focusFirstError,
    scrollDuration,
    scrollCurve,
    scrollAlignment,
    errorAnimation,
  );
}

/// Supplies behavior defaults to descendant `SmartForm` widgets.
///
/// Values set directly on a form take precedence over this theme.
class SmartFormTheme extends InheritedTheme {
  /// Creates a theme that exposes [data] to [child].
  const SmartFormTheme({required this.data, required super.child, super.key});

  /// Behavior defaults exposed to descendant forms.
  final SmartFormThemeData data;

  /// Returns the closest theme data or package defaults when none exists.
  static SmartFormThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SmartFormTheme>()?.data ??
        const SmartFormThemeData();
  }

  /// Returns the closest theme data, or null when no theme is present.
  static SmartFormThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SmartFormTheme>()?.data;
  }

  @override
  bool updateShouldNotify(SmartFormTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return SmartFormTheme(data: data, child: child);
  }
}
