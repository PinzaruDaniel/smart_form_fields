import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  runApp(const SmartFormFieldsExampleApp());
}

class SmartFormFieldsExampleApp extends StatelessWidget {
  const SmartFormFieldsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF315C4C);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Form Fields example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const RegistrationExamplePage(),
    );
  }
}

class RegistrationExamplePage extends StatefulWidget {
  const RegistrationExamplePage({super.key});

  @override
  State<RegistrationExamplePage> createState() =>
      _RegistrationExamplePageState();
}

class _RegistrationExamplePageState extends State<RegistrationExamplePage> {
  final SmartFormController _formController = SmartFormController();
  late final List<SmartValidator<String>> _emailValidators;
  late final List<SmartValidator<String>> _phoneValidators;
  late final List<SmartValidator<String>> _passwordValidators;
  late final List<SmartValidator<String>> _confirmationValidators;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailValidators = <SmartValidator<String>>[
      SmartValidators.required<String>(message: 'Email is required'),
      SmartValidators.email(),
    ];
    _phoneValidators = <SmartValidator<String>>[
      SmartValidators.required<String>(message: 'Phone is required'),
      _phone,
    ];
    _passwordValidators = <SmartValidator<String>>[
      SmartValidators.required<String>(message: 'Password is required'),
      SmartValidators.minLength<String>(
        8,
        message: 'Use at least 8 characters',
      ),
    ];
    _confirmationValidators = <SmartValidator<String>>[
      SmartValidators.required<String>(
        message: 'Password confirmation is required',
      ),
      _confirmPassword,
    ];
  }

  static String? _phone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 ? null : 'Enter at least 8 digits';
  }

  Future<String?> _checkEmailAvailability(String? value) async {
    if (value == null || value.isEmpty) {
      return null;
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (value.toLowerCase() == 'taken@example.com') {
      return 'This email is already registered';
    }
    return null;
  }

  String? _confirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value == _formController.valueOf<String>('password')
        ? null
        : 'Passwords do not match';
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await _formController.validate();
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isValid
              ? 'Account data is valid for ${result.values['email']}'
              : 'Please correct ${result.errors.length} field(s).',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _fillSample() {
    _formController.patchValue(<String, Object?>{
      'firstName': 'Ana',
      'lastName': 'Popescu',
      'email': 'ana@example.com',
      'phone': '+373 60 123 456',
      'password': 'flutter123',
      'confirmPassword': 'flutter123',
      'newsletter': true,
    });
  }

  void _reset() {
    _formController.reset();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Future<void> _showServerErrors() async {
    await _formController.setErrors(const <String, String>{
      'email': 'The server rejected this email address',
      'phone': 'The server could not verify this phone number',
    }, scrollToFirstError: true);
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart form example'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset form',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
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
                    Icons.fact_check_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This demo shows registration, validation, value patching, '
                    'server errors, reset, and first-error navigation.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SmartForm(
                    controller: _formController,
                    children: <Widget>[
                      const _NameFields(),
                      const SizedBox(height: 16),
                      SmartTextField(
                        name: 'email',
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validators: _emailValidators,
                        asyncValidators: <SmartAsyncValidator<String>>[
                          _checkEmailAvailability,
                        ],
                        asyncValidationDebounce: const Duration(
                          milliseconds: 400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SmartTextField(
                        name: 'phone',
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          hintText: '+373 60 123 456',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d\s+()-]'),
                          ),
                        ],
                        validators: _phoneValidators,
                      ),
                      const SizedBox(height: 16),
                      SmartTextField(
                        name: 'password',
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        validators: _passwordValidators,
                      ),
                      const SizedBox(height: 16),
                      SmartTextField(
                        name: 'confirmPassword',
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        validators: _confirmationValidators,
                        onSubmitted: (_) => unawaited(_submit()),
                      ),
                      const SizedBox(height: 12),
                      SmartFormField<bool>(
                        name: 'newsletter',
                        initialValue: false,
                        builder: (context, field) {
                          return Card(
                            margin: EdgeInsets.zero,
                            child: SwitchListTile(
                              title: const Text('Product updates'),
                              subtitle: const Text(
                                'A custom boolean field built with '
                                'SmartFormField<bool>.',
                              ),
                              value: field.value ?? false,
                              onChanged: field.enabled ? field.didChange : null,
                            ),
                          );
                        },
                      ),
                    ],
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
                      _isSubmitting ? 'Validating…' : 'Create account',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: _fillSample,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('Fill sample'),
                      ),
                      TextButton.icon(
                        onPressed: _showServerErrors,
                        icon: const Icon(Icons.cloud_off_outlined),
                        label: const Text('Show server errors'),
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

class _NameFields extends StatelessWidget {
  const _NameFields();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final firstName = SmartTextField(
          name: 'firstName',
          decoration: const InputDecoration(labelText: 'First name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validators: <SmartValidator<String>>[
            SmartValidators.required<String>(message: 'First name is required'),
          ],
        );
        final lastName = SmartTextField(
          name: 'lastName',
          decoration: const InputDecoration(labelText: 'Last name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validators: <SmartValidator<String>>[
            SmartValidators.required<String>(message: 'Last name is required'),
          ],
        );

        if (constraints.maxWidth < 520) {
          return Column(
            children: <Widget>[firstName, const SizedBox(height: 16), lastName],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: firstName),
            const SizedBox(width: 16),
            Expanded(child: lastName),
          ],
        );
      },
    );
  }
}
