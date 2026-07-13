import 'package:flutter/widgets.dart';

import '../animation/smart_error_animation.dart';
import 'smart_field_handle.dart';

abstract interface class SmartFormRegistrar {
  void registerField(
    SmartFieldHandle<Object?> field, {
    required int sectionOrder,
  });

  void unregisterField(SmartFieldHandle<Object?> field);
}

final class SmartFormScope extends InheritedWidget {
  const SmartFormScope({
    required this.registrar,
    required this.scrollDuration,
    required this.scrollCurve,
    required this.scrollAlignment,
    required this.errorAnimation,
    required super.child,
    super.key,
  });

  final SmartFormRegistrar registrar;
  final Duration scrollDuration;
  final Curve scrollCurve;
  final double scrollAlignment;
  final SmartErrorAnimation errorAnimation;

  static SmartFormScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SmartFormScope>();
  }

  static SmartFormScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw FlutterError(
        'No SmartForm found above this field. Smart fields must be placed '
        'below a SmartForm.',
      );
    }
    return scope;
  }

  @override
  bool updateShouldNotify(SmartFormScope oldWidget) {
    return !identical(registrar, oldWidget.registrar) ||
        scrollDuration != oldWidget.scrollDuration ||
        scrollCurve != oldWidget.scrollCurve ||
        scrollAlignment != oldWidget.scrollAlignment ||
        errorAnimation != oldWidget.errorAnimation;
  }
}

final class SmartFormOrderScope extends InheritedWidget {
  const SmartFormOrderScope({
    required this.order,
    required super.child,
    super.key,
  });

  final int order;

  static int of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<SmartFormOrderScope>()
            ?.order ??
        0;
  }

  @override
  bool updateShouldNotify(SmartFormOrderScope oldWidget) {
    return order != oldWidget.order;
  }
}
