import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

class JsonFormExamplePage extends StatefulWidget {
  const JsonFormExamplePage({super.key});

  @override
  State<JsonFormExamplePage> createState() => _JsonFormExamplePageState();
}

class _JsonFormExamplePageState extends State<JsonFormExamplePage> {
  static const Map<String, Object?> _apiResponse = <String, Object?>{
    'scroll_to_first_error': true,
    'focus_first_error': true,
    'error_animation': 'shake',
    'fields': <Object?>[
      <String, Object?>{
        'type': 'email',
        'name': 'email',
        'label_text': 'Work email',
        'hint_text': 'name@company.com',
        'required': true,
        'required_message': 'Work email is required',
        'async_validators': <Object?>['email_available'],
      },
      <String, Object?>{
        'type': 'text',
        'name': 'display_name',
        'label_text': 'Display name',
        'required': true,
        'validators': <Object?>[
          <String, Object?>{
            'type': 'min_length',
            'value': 3,
            'message': 'Use at least 3 characters',
          },
          <String, Object?>{
            'type': 'not_reserved',
            'message': 'This display name is reserved',
          },
        ],
      },
      <String, Object?>{
        'type': 'dropdown',
        'name': 'role',
        'label_text': 'Role',
        'required': true,
        'required_message': 'Choose a role',
        'options': <Object?>[
          <String, Object?>{'value': 'developer', 'label': 'Developer'},
          <String, Object?>{'value': 'designer', 'label': 'Designer'},
          <String, Object?>{'value': 'manager', 'label': 'Manager'},
        ],
      },
      <String, Object?>{
        'type': 'text',
        'name': 'company_name',
        'label_text': 'Company name (required for managers)',
        'validators': <Object?>[
          <String, Object?>{
            'type': 'required_when',
            'field': 'role',
            'equals': 'manager',
            'message': 'Company name is required for managers',
          },
        ],
      },
      <String, Object?>{
        'type': 'password',
        'name': 'password',
        'label_text': 'Password',
        'required': true,
        'min_length': 8,
      },
      <String, Object?>{
        'type': 'password',
        'name': 'confirm_password',
        'label_text': 'Confirm password',
        'required': true,
        'validators': <Object?>[
          <String, Object?>{
            'type': 'matches_field',
            'field': 'password',
            'message': 'Passwords do not match',
          },
        ],
      },
      <String, Object?>{
        'type': 'agreement',
        'name': 'terms',
        'initial_value': false,
        'validators': <Object?>[
          <String, Object?>{
            'type': 'must_be_true',
            'message': 'Accept the API usage terms',
          },
        ],
      },
    ],
  };

  final SmartFormController _controller = SmartFormController();
  late final Widget _jsonForm;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _jsonForm = SmartJsonForm.fromJson(
      json: _apiResponse,
      controller: _controller,
      asyncValidators: <String, SmartAsyncValidator<Object?>>{
        'email_available': _emailAvailable,
      },
      customValidatorBuilders: <String, SmartJsonValidatorBuilder>{
        'not_reserved': (definition) {
          return (value) => value?.toString().toLowerCase() == 'admin'
              ? definition.message
              : null;
        },
        'must_be_true': (definition) {
          return (value) => value == true ? null : definition.message;
        },
      },
      customFieldBuilders: <String, SmartJsonFieldBuilder>{
        'agreement': _agreementField,
      },
    );
  }

  Future<String?> _emailAvailable(Object? value) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return value == 'used@example.com' ? 'This email is already used' : null;
  }

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
              ? 'JSON values: ${result.values}'
              : 'JSON form has ${result.errors.length} error(s)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _fillSample() {
    _controller.patchValue(const <String, Object?>{
      'email': 'api@example.com',
      'display_name': 'API user',
      'role': 'developer',
      'company_name': '',
      'password': 'flutter123',
      'confirm_password': 'flutter123',
      'terms': true,
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
      appBar: AppBar(
        title: const Text('JSON API form'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset JSON form',
            onPressed: _controller.reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: <Widget>[
                Text(
                  'Rendered from a snake_case API response',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The server describes fields and validation metadata. The '
                  'application registers executable async and custom behavior.',
                ),
                const SizedBox(height: 24),
                _jsonForm,
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.schema_outlined),
                  label: Text(
                    _isSubmitting ? 'Validating JSON…' : 'Validate JSON form',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _fillSample,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text('Fill JSON sample'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _agreementField(
    BuildContext context,
    SmartJsonFieldDefinition definition,
    List<SmartValidator<Object?>> validators,
    List<SmartAsyncValidator<Object?>> asyncValidators,
  ) {
    return SmartFormField<Object?>(
      name: definition.name,
      initialValue: definition.properties['initial_value'],
      validators: validators,
      asyncValidators: asyncValidators,
      builder: (context, field) {
        return Card(
          margin: EdgeInsets.zero,
          child: SwitchListTile(
            title: const Text('Accept API usage terms'),
            subtitle: Text(
              field.errorText ?? 'Custom field builder registered as agreement',
              style: field.errorText == null
                  ? null
                  : TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            value: field.value == true,
            onChanged: field.enabled ? field.didChange : null,
          ),
        );
      },
    );
  }
}
