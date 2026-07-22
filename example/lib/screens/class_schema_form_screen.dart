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
  final List<ApiField> _apiFields = const <ApiField>[
    TextApiField(
      name: 'display_name',
      label: 'Display name',
      required: true,
      minimumLength: 3,
      validationMessage: 'Use at least 3 characters',
    ),
    EmailApiField(
      name: 'email',
      label: 'Email',
      required: true,
      requiredMessage: 'Email is required',
    ),
    PasswordApiField(
      name: 'password',
      label: 'Password',
      required: true,
      minimumLength: 8,
      validationMessage: 'Use at least 8 characters',
    ),
    PasswordApiField(
      name: 'confirm_password',
      label: 'Confirm password',
      required: true,
      matchesField: 'password',
      validationMessage: 'Passwords do not match',
    ),
    DropdownApiField(
      name: 'country',
      label: 'Country',
      required: true,
      options: <ApiOption>[
        ApiOption(value: 'md', label: 'Moldova'),
        ApiOption(value: 'ro', label: 'Romania'),
        ApiOption(value: 'ua', label: 'Ukraine'),
      ],
    ),
  ];

  SmartFieldDefinition _mapApiField(ApiField field) {
    return switch (field) {
      TextApiField field => SmartFieldDefinition.text(
        name: field.name,
        labelText: field.label,
        required: field.required,
        validators: <SmartValidatorDefinition>[
          if (field.minimumLength case final length?)
            SmartValidatorDefinition.minLength(
              length,
              message: field.validationMessage,
            ),
        ],
      ),
      EmailApiField field => SmartFieldDefinition.email(
        name: field.name,
        labelText: field.label,
        required: field.required,
        requiredMessage: field.requiredMessage,
      ),
      PasswordApiField field => SmartFieldDefinition.password(
        name: field.name,
        labelText: field.label,
        required: field.required,
        minLength: field.minimumLength,
        minLengthMessage: field.matchesField == null
            ? field.validationMessage
            : null,
        validators: <SmartValidatorDefinition>[
          if (field.matchesField case final source?)
            SmartValidatorDefinition.matchesField(
              source,
              message: field.validationMessage,
            ),
        ],
      ),
      DropdownApiField field => SmartFieldDefinition.dropdown(
        name: field.name,
        labelText: field.label,
        required: field.required,
        options: <SmartOptionDefinition>[
          for (final option in field.options)
            SmartOptionDefinition(value: option.value, label: option.label),
        ],
      ),
    };
  }

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
                  'Rendered from API model classes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The API response is decoded into EmailApiField, '
                  'PasswordApiField, and other DTOs. One typed mapper lets '
                  'the package render the complete model list.',
                ),
                const SizedBox(height: 24),
                SmartSchemaForm.fromClasses<ApiField>(
                  fields: _apiFields,
                  fieldMapper: _mapApiField,
                  controller: _controller,
                  scrollToFirstError: true,
                  focusFirstError: true,
                  errorAnimation: SmartErrorAnimation.fade,
                ),
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

sealed class ApiField {
  const ApiField({
    required this.name,
    required this.label,
    required this.required,
  });

  final String name;
  final String label;
  final bool required;
}

final class TextApiField extends ApiField {
  const TextApiField({
    required super.name,
    required super.label,
    required super.required,
    this.minimumLength,
    this.validationMessage,
  });

  final int? minimumLength;
  final String? validationMessage;
}

final class EmailApiField extends ApiField {
  const EmailApiField({
    required super.name,
    required super.label,
    required super.required,
    this.requiredMessage,
  });

  final String? requiredMessage;
}

final class PasswordApiField extends ApiField {
  const PasswordApiField({
    required super.name,
    required super.label,
    required super.required,
    this.minimumLength,
    this.matchesField,
    this.validationMessage,
  });

  final int? minimumLength;
  final String? matchesField;
  final String? validationMessage;
}

final class DropdownApiField extends ApiField {
  const DropdownApiField({
    required super.name,
    required super.label,
    required super.required,
    required this.options,
  });

  final List<ApiOption> options;
}

final class ApiOption {
  const ApiOption({required this.value, required this.label});

  final Object? value;
  final String label;
}
