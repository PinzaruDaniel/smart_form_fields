import 'package:flutter/material.dart';

import 'controller_playground_screen.dart';
import 'json_form_screen.dart';
import 'registration_form_screen.dart';

class ExampleHomeScreen extends StatelessWidget {
  const ExampleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Form Fields')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: <Widget>[
            Text('Package examples', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Open a focused example to see widget-authored forms, API JSON '
              'schemas, and imperative form control.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _DemoCard(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Registration form',
              description:
                  'Reusable fields, sync and async validation, validation '
                  'timing, first-error navigation, reset, and submission.',
              onTap: () => _open(context, const RegistrationExamplePage()),
            ),
            const SizedBox(height: 12),
            _DemoCard(
              icon: Icons.data_object_outlined,
              title: 'JSON API form',
              description:
                  'Snake-case API schema, named async validation, custom '
                  'validator builders, and a custom JSON field type.',
              onTap: () => _open(context, const JsonFormExamplePage()),
            ),
            const SizedBox(height: 12),
            _DemoCard(
              icon: Icons.tune_outlined,
              title: 'Controller playground',
              description:
                  'Values, patching, server errors, focus and scroll commands, '
                  'disabled fields, and a bottom-sheet custom field.',
              onTap: () => _open(context, const ControllerPlaygroundPage()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: colors.onSecondaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
