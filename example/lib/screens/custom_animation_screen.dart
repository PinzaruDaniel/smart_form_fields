import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

class CustomAnimationExamplePage extends StatefulWidget {
  const CustomAnimationExamplePage({super.key});

  @override
  State<CustomAnimationExamplePage> createState() =>
      _CustomAnimationExamplePageState();
}

class _CustomAnimationExamplePageState
    extends State<CustomAnimationExamplePage> {
  final SmartFormController _controller = SmartFormController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _customErrorAnimation(
    BuildContext context,
    Widget child,
    Animation<double> animation,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final progress = curved.value;
        final wobble = math.sin(progress * math.pi * 3) * (1 - progress);
        return Transform.translate(
          offset: Offset(0, -10 * (1 - progress)),
          child: Transform.rotate(
            angle: wobble * 0.035,
            child: Transform.scale(scale: 0.98 + progress * 0.02, child: child),
          ),
        );
      },
    );
  }

  Future<void> _validate() async {
    final result = await _controller.validate();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.isValid
                ? 'Custom animation form is valid.'
                : 'Custom animation wrapped ${result.errors.length} field(s).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _fillSample() {
    _controller.patchValue(<String, Object?>{
      'display_name': 'Animated User',
      'email': 'animation@example.com',
      'message': 'Custom error animation builder is active.',
    });
  }

  void _reset() {
    _controller.reset();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Custom error animation')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.animation_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Application-owned error animation',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This form uses SmartForm.errorAnimationBuilder to wrap '
                    'invalid fields with a custom slide, rotate, and scale '
                    'animation.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SmartForm(
                    controller: _controller,
                    errorAnimationBuilder: _customErrorAnimation,
                    children: <Widget>[
                      SmartTextField(
                        name: 'display_name',
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validators: <SmartValidator>[
                          SmartValidators.required(
                            message: 'Display name is required',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SmartEmailField(
                        name: 'email',
                        required: true,
                        requiredMessage: 'Email is required',
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      SmartTextField(
                        name: 'message',
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        validators: <SmartValidator>[
                          SmartValidators.minLength(
                            12,
                            message: 'Use at least 12 characters',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Validate custom animation'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: _fillSample,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('Fill sample'),
                      ),
                      TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
