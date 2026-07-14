import 'package:flutter/widgets.dart';

import '../animation/smart_error_animation.dart';

/// Behavior defaults for descendant `SmartForm` widgets.
@immutable
class SmartFormThemeData {
  const SmartFormThemeData({
    this.scrollToFirstError = true,
    this.focusFirstError = true,
    this.scrollDuration = const Duration(milliseconds: 350),
    this.scrollCurve = Curves.easeOutCubic,
    this.scrollAlignment = 0.2,
    this.errorAnimation = SmartErrorAnimation.shake,
  });

  final bool scrollToFirstError;
  final bool focusFirstError;
  final Duration scrollDuration;
  final Curve scrollCurve;
  final double scrollAlignment;
  final SmartErrorAnimation errorAnimation;

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
  const SmartFormTheme({required this.data, required super.child, super.key});

  final SmartFormThemeData data;

  static SmartFormThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SmartFormTheme>()?.data ??
        const SmartFormThemeData();
  }

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
