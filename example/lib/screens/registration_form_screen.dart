import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

class RegistrationExamplePage extends StatefulWidget {
  const RegistrationExamplePage({super.key});

  @override
  State<RegistrationExamplePage> createState() =>
      _RegistrationExamplePageState();
}

class _RegistrationExamplePageState extends State<RegistrationExamplePage> {
  final SmartFormController _formController = SmartFormController();
  String _phoneCountryCode = '+373';

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

  Future<void> _submit() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  void _showSubmitResult() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Account data is valid for '
            '${_formController.lastSubmitResult?.values['email']}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showSubmitError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registration failed: $error'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _fillSample() async {
    _formController.patchValue(<String, Object?>{
      'firstName': 'Ana',
      'lastName': 'Popescu',
      'email': 'ana@example.com',
      'phone': '60 123 456',
      'password': 'flutter123',
      'confirmPassword': 'flutter123',
      'birthDate': DateTime(1992, 5, 14),
      'country': 'Moldova',
      'accountType': 'Business',
      'newsletter': true,
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && _formController.values.containsKey('companyName')) {
      _formController.setValue<String>('companyName', 'Smart Moldova SRL');
    }
  }

  void _reset() {
    _formController.reset();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Future<void> _showServerErrors() async {
    final result = await _formController.setErrorsFromResponse(
      const <String, Object?>{
        'success': false,
        'message': 'The server rejected the registration',
        'data': <String, Object?>{
          'validation_errors': <String, Object?>{
            'email': <String>['The server rejected this email address'],
            'phone_number': <String>[
              'The server could not verify this phone number',
            ],
          },
        },
      },
      fieldAliases: const <String, String>{'phone_number': 'phone'},
      scrollToFirstError: true,
    );
    if (mounted && result.generalErrors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.generalErrors.first)));
    }
  }

  Future<void> _selectPhoneCountry() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final country in const <(String, String)>[
              ('Moldova', '+373'),
              ('Romania', '+40'),
              ('Ukraine', '+380'),
            ])
              ListTile(
                title: Text(country.$1),
                trailing: Text(country.$2),
                onTap: () => Navigator.pop(context, country.$2),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _phoneCountryCode = selected);
    }
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final smartPhoneFieldViewItem = SmartPhoneFieldViewItem(
      name: 'phone',
      autovalidateMode: .onUnfocus,
      countrySelector: GestureDetector(
        onTap: _selectPhoneCountry,
        child: Text(_phoneCountryCode),
      ),
      countrySelectorSeparator: const VerticalDivider(width: 1),
      required: true,
      requiredMessage: 'Phone is required',
      decoration: const InputDecoration(
        labelText: 'Phone',
        hintText: '60 123 456',
      ),
      textInputAction: TextInputAction.next,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s+()-]')),
      ],
      valueParser: (formatted) => SmartPhoneValue(
        formatted: formatted,
        e164: '$_phoneCountryCode${formatted.replaceAll(RegExp(r'\D'), '')}',
      ),
      validators: <SmartValidator>[_phone],
    );

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
                    onSubmit: (_) => _submit(),
                    children: <Widget>[
                      const _NameFields(),
                      const SizedBox(height: 16),
                      SmartEmailField(
                        name: 'email',
                        required: true,
                        requiredMessage: 'Email is required',
                        autovalidateMode: .onUnfocus,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        asyncValidators: <SmartAsyncValidator<String>>[
                          _checkEmailAvailability,
                        ],
                      ),
                      const SizedBox(height: 16),
                      SmartPhoneField(item: smartPhoneFieldViewItem),
                      const SizedBox(height: 16),
                      SmartPasswordField(
                        name: 'password',
                        required: true,
                        requiredMessage: 'Password is required',
                        minLength: 8,
                        minLengthMessage: 'Use at least 8 characters',
                        autovalidateMode: .onUserInteractionIfError,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        excludeFromDraft: true,
                      ),
                      const SizedBox(height: 16),
                      SmartPasswordField(
                        name: 'confirmPassword',
                        required: true,
                        requiredMessage: 'Password confirmation is required',
                        minLength: null,
                        autovalidateMode: .disabled,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                        validators: <SmartValidator>[
                          SmartValidators.matchesField(
                            'password',
                            message: 'Passwords do not match',
                          ),
                        ],
                        onSubmitted: (_) => unawaited(_formController.submit()),
                        excludeFromDraft: true,
                      ),
                      const SizedBox(height: 16),
                      SmartDateField(
                        name: 'birthDate',
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        required: true,
                        requiredMessage: 'Birth date is required',
                        decoration: const InputDecoration(
                          labelText: 'Birth date',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SmartDropdownField<String>(
                        name: 'country',
                        items: const <String>['Moldova', 'Romania', 'Ukraine'],
                        itemLabelBuilder: (country) => country,
                        required: true,
                        requiredMessage: 'Country is required',
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          prefixIcon: Icon(Icons.public_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SmartDropdownField<String>(
                        name: 'accountType',
                        items: const <String>['Personal', 'Business'],
                        itemLabelBuilder: (value) => value,
                        required: true,
                        requiredMessage: 'Account type is required',
                        decoration: const InputDecoration(
                          labelText: 'Account type',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SmartConditionalField(
                        dependsOn: 'accountType',
                        condition: (value, _) => value == 'Business',
                        child: SmartTextField(
                          name: 'companyName',
                          decoration: const InputDecoration(
                            labelText: 'Company name',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validators: <SmartValidator>[
                            SmartValidators.required(
                              message: 'Company name is required',
                            ),
                          ],
                        ),
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
                  SmartSubmitButton(
                    controller: _formController,
                    onSubmitted: _showSubmitResult,
                    onError: _showSubmitError,
                    loadingChild: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Creating account...'),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text('Create account'),
                      ],
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
          autovalidateMode: .disabled,
          decoration: const InputDecoration(labelText: 'First name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validators: <SmartValidator>[
            SmartValidators.required(message: 'First name is required'),
          ],
        );
        final lastName = SmartTextField(
          name: 'lastName',
          decoration: const InputDecoration(labelText: 'Last name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validators: <SmartValidator>[
            SmartValidators.required(message: 'Last name is required'),
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
