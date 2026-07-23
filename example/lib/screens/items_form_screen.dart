import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

class ItemsFormExamplePage extends StatefulWidget {
  const ItemsFormExamplePage({super.key});

  @override
  State<ItemsFormExamplePage> createState() => _ItemsFormExamplePageState();
}

class _ItemsFormExamplePageState extends State<ItemsFormExamplePage> {
  final SmartFormController _controller = SmartFormController();
  String _callingCode = '+373';
  bool _isValidating = false;

  List<SmartFieldViewItem> _buildItems() {
    return <SmartFieldViewItem>[
      SmartWidgetFieldViewItem(
        name: 'display_name',
        builder: (_) => SmartTextField(
          name: 'display_name',
          decoration: const InputDecoration(
            labelText: 'Display name',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validators: <SmartValidator>[
            SmartValidators.required(message: 'Display name is required'),
          ],
        ),
      ),
      SmartWidgetFieldViewItem(
        name: 'email',
        builder: (_) => const SmartEmailField(
          name: 'email',
          required: true,
          requiredMessage: 'Email is required',
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          textInputAction: TextInputAction.next,
        ),
      ),
      SmartPhoneFieldViewItem(
        name: 'phone',
        required: true,
        requiredMessage: 'Phone is required',
        countrySelector: InkWell(
          onTap: _selectCallingCode,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_callingCode),
          ),
        ),
        countrySelectorSeparator: const VerticalDivider(width: 1),
        decoration: const InputDecoration(
          labelText: 'Phone',
          hintText: '780 59 426',
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]')),
        ],
        valueParser: (formatted) => SmartPhoneValue(
          formatted: formatted,
          e164: '$_callingCode${formatted.replaceAll(RegExp(r'\D'), '')}',
        ),
        textInputAction: TextInputAction.next,
      ),
      SmartWidgetFieldViewItem(
        name: 'account_type',
        builder: (_) => SmartDropdownField<String>(
          name: 'account_type',
          items: const <String>['Personal', 'Business', 'Creator'],
          itemLabelBuilder: (value) => value,
          required: true,
          requiredMessage: 'Account type is required',
          decoration: const InputDecoration(
            labelText: 'Account type',
            prefixIcon: Icon(Icons.account_circle_outlined),
          ),
        ),
      ),
      SmartWidgetFieldViewItem(
        name: 'product_updates',
        builder: (_) => SmartFormField<bool>(
          name: 'product_updates',
          initialValue: false,
          builder: (context, field) => Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Product updates'),
              subtitle: const Text('A custom item built with SmartFormField.'),
              value: field.value ?? false,
              onChanged: field.enabled ? field.didChange : null,
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _selectCallingCode() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final option in const <(String, String)>[
              ('Moldova', '+373'),
              ('Romania', '+40'),
              ('Ukraine', '+380'),
            ])
              ListTile(
                title: Text(option.$1),
                trailing: Text(option.$2),
                onTap: () => Navigator.pop(context, option.$2),
              ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _callingCode = result);
    }
  }

  void _fillSample() {
    _controller.patchValue(<String, Object?>{
      'display_name': 'Mara Ionescu',
      'email': 'mara@example.com',
      'phone': '780 59 426',
      'account_type': 'Creator',
      'product_updates': true,
    });
  }

  Future<void> _validate() async {
    if (_isValidating) {
      return;
    }
    setState(() => _isValidating = true);
    final result = await _controller.validate();
    if (!mounted) {
      return;
    }
    setState(() => _isValidating = false);

    final phone = result.values['phone'];
    final phoneSummary = phone is SmartPhoneValue ? phone.e164 : phone;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.isValid
                ? 'Items form is valid: $phoneSummary'
                : 'Correct ${result.errors.length} item field(s).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _reset() {
    _controller.reset();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Item-driven form')),
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
                    Icons.view_list_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Built entirely from field items',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every field below comes from SmartForm.items, with one '
                    'shared separator height and normal controller behavior.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SmartForm(
                    controller: _controller,
                    items: _buildItems(),
                    itemSeparatorHeight: 16,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isValidating ? null : _validate,
                    icon: _isValidating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isValidating ? 'Validating items…' : 'Validate items',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: _fillSample,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('Fill item sample'),
                      ),
                      TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset items'),
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
