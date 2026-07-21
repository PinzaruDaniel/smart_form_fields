import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

class ClassSchemaFormExamplePage extends StatefulWidget {
  const ClassSchemaFormExamplePage({super.key});

  @override
  State<ClassSchemaFormExamplePage> createState() =>
      _ClassSchemaFormExamplePageState();
}

class _ClassSchemaFormExamplePageState
    extends State<ClassSchemaFormExamplePage> {
  final SmartFormController _controller = SmartFormController();
  late final SmartFormSchema _schema = SmartFormSchema(
    scrollToFirstError: true,
    focusFirstError: true,
    errorAnimation: SmartErrorAnimation.fade,
    fields: <SmartFieldDefinition>[
      SmartFieldDefinition.text(
        name: 'display_name',
        labelText: 'Display name',
        required: true,
        validators: <SmartValidatorDefinition>[
          SmartValidatorDefinition.minLength(
            3,
            message: 'Use at least 3 characters',
          ),
        ],
      ),
      SmartFieldDefinition.email(
        name: 'email',
        labelText: 'Email',
        required: true,
        requiredMessage: 'Email is required',
      ),
      SmartFieldDefinition.password(
        name: 'password',
        labelText: 'Password',
        required: true,
        minLengthMessage: 'Use at least 8 characters',
      ),
      SmartFieldDefinition.password(
        name: 'confirm_password',
        labelText: 'Confirm password',
        required: true,
        minLength: null,
        validators: <SmartValidatorDefinition>[
          SmartValidatorDefinition.matchesField(
            'password',
            message: 'Passwords do not match',
          ),
        ],
      ),
      SmartFieldDefinition.dropdown(
        name: 'country',
        labelText: 'Country',
        required: true,
        options: const <SmartOptionDefinition>[
          SmartOptionDefinition(value: 'md', label: 'Moldova'),
          SmartOptionDefinition(value: 'ro', label: 'Romania'),
          SmartOptionDefinition(value: 'ua', label: 'Ukraine'),
        ],
      ),
    ],
  );

  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final result = await _controller.validate();
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isValid
              ? 'Class schema values: ${result.values}'
              : 'Class schema has ${result.errors.length} error(s)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _fillSample() {
    _controller.patchValue(const <String, Object?>{
      'display_name': 'Ana',
      'email': 'ana@example.com',
      'password': 'flutter123',
      'confirm_password': 'flutter123',
      'country': 'md',
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class-defined form')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: <Widget>[
                Text(
                  'Rendered from Dart definition classes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'SmartFormSchema and SmartFieldDefinition use the same '
                  'renderer as JSON without requiring maps or decoding.',
                ),
                const SizedBox(height: 24),
                SmartSchemaForm(schema: _schema, controller: _controller),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting
                        ? 'Validating classes…'
                        : 'Validate class form',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _fillSample,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text('Fill class sample'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
