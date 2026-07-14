import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

class ControllerPlaygroundPage extends StatefulWidget {
  const ControllerPlaygroundPage({super.key});

  @override
  State<ControllerPlaygroundPage> createState() =>
      _ControllerPlaygroundPageState();
}

class _ControllerPlaygroundPageState extends State<ControllerPlaygroundPage> {
  final SmartFormKey _formKey = SmartFormKey();
  final SmartFormController _controller = SmartFormController();
  bool _showReferralField = true;

  Future<void> _validateWithKey() async {
    final result = await _formKey.validate();
    if (!mounted) {
      return;
    }
    _showMessage(
      result.isValid
          ? 'Key validation passed: ${result.values}'
          : 'Key validation found ${result.errors.length} error(s)',
    );
  }

  void _showValues() {
    _showMessage('Controller values: ${_controller.values}');
  }

  void _patchValues() {
    _controller.patchValue(<String, Object?>{
      'project_name': 'Smart checkout',
      'budget': '2500',
      'delivery': 'Monthly',
      if (_showReferralField) 'referral': 'PACKAGE-DEMO',
    });
  }

  Future<void> _showServerErrors() async {
    await _controller.setErrors(const <String, String>{
      'project_name': 'The server rejected this project name',
      'delivery': 'This delivery option is temporarily unavailable',
    }, scrollToFirstError: true);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controller playground')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: <Widget>[
                Text(
                  'Imperative form controls',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This form is connected to both SmartFormKey and '
                  'SmartFormController. Try the actions after editing fields.',
                ),
                const SizedBox(height: 24),
                SmartForm(
                  key: _formKey,
                  controller: _controller,
                  children: <Widget>[
                    SmartTextField(
                      name: 'project_name',
                      decoration: const InputDecoration(
                        labelText: 'Project name',
                      ),
                      validators: <SmartValidator<String>>[
                        SmartValidators.required<String>(
                          message: 'Project name is required',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SmartTextField(
                      name: 'account_id',
                      initialValue: 'ACCOUNT-1042',
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Disabled account ID',
                        helperText:
                            'Disabled fields stay in values but are not validated.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SmartTextField(
                      name: 'budget',
                      decoration: const InputDecoration(
                        labelText: 'Budget',
                        prefixText: '€ ',
                      ),
                      validators: <SmartValidator<String>>[
                        SmartValidators.number<String>(
                          message: 'Enter a numeric budget',
                        ),
                        SmartValidators.min<String>(
                          100,
                          message: 'Budget must be at least 100',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BottomSheetSelectionField(name: 'delivery'),
                    const SizedBox(height: 16),
                    if (_showReferralField)
                      SmartTextField(
                        name: 'referral',
                        decoration: const InputDecoration(
                          labelText: 'Dynamic referral code',
                          helperText: 'Remove and add this registered field.',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton(
                      onPressed: _validateWithKey,
                      child: const Text('Validate with key'),
                    ),
                    OutlinedButton(
                      onPressed: _showValues,
                      child: const Text('Read values'),
                    ),
                    OutlinedButton(
                      onPressed: _patchValues,
                      child: const Text('Patch values'),
                    ),
                    OutlinedButton(
                      onPressed: () => _controller.setValue<String>(
                        'project_name',
                        'Set with controller',
                      ),
                      child: const Text('Set project name'),
                    ),
                    OutlinedButton(
                      onPressed: _showServerErrors,
                      child: const Text('Set server errors'),
                    ),
                    OutlinedButton(
                      onPressed: _controller.clearErrors,
                      child: const Text('Clear errors'),
                    ),
                    OutlinedButton(
                      onPressed: () => _controller.setFieldError(
                        'budget',
                        'Single field error from the server',
                      ),
                      child: const Text('Set one error'),
                    ),
                    OutlinedButton(
                      onPressed: () => _controller.focusField('project_name'),
                      child: const Text('Focus first field'),
                    ),
                    OutlinedButton(
                      onPressed: () => _controller.scrollToField('delivery'),
                      child: const Text('Scroll to picker'),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(
                        () => _showReferralField = !_showReferralField,
                      ),
                      child: Text(
                        _showReferralField
                            ? 'Remove dynamic field'
                            : 'Add dynamic field',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _controller.reset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetSelectionField extends StatelessWidget {
  const _BottomSheetSelectionField({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SmartFormField<String>(
      name: name,
      validators: <SmartValidator<String>>[
        SmartValidators.required<String>(message: 'Choose a delivery schedule'),
      ],
      builder: (context, field) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: field.enabled
              ? () async {
                  final value = await showModalBottomSheet<String>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => const _DeliverySheet(),
                  );
                  if (value != null) {
                    field.didChange(value);
                  }
                }
              : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Delivery schedule',
              helperText: 'A SmartFormField opened with a bottom sheet.',
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.expand_more),
            ),
            child: Text(field.value ?? 'Choose schedule'),
          ),
        );
      },
    );
  }
}

class _DeliverySheet extends StatelessWidget {
  const _DeliverySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          for (final value in const <String>['Weekly', 'Monthly', 'Quarterly'])
            ListTile(
              title: Text(value),
              onTap: () => Navigator.of(context).pop(value),
            ),
        ],
      ),
    );
  }
}
