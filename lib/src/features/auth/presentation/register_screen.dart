import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/service_cities.dart';
import '../domain/customer.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _gstin = TextEditingController();
  final _password = TextEditingController();

  String? _city; // selected from the serviceable-cities dropdown

  @override
  void dispose() {
    _shopName.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _email.dispose();
    _gstin.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);
    try {
      final result = await ref.read(authControllerProvider.notifier).register(
            shopName: _shopName.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            city: _city!.trim(),
            ownerName: _ownerName.text.trim(),
            email: _email.text.trim(),
            gstin: _gstin.text.trim(),
          );
      if (!mounted) return;
      // Registration is approval-gated — show the pending screen, don't sign in.
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => _PendingApprovalScreen(result: result)),
      );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Register your store')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _shopName,
                  decoration: const InputDecoration(
                    labelText: 'Business / Store name',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Enter your store name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerName,
                  decoration: const InputDecoration(
                    labelText: 'Owner name (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixText: '+91 ',
                    counterText: '',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.length != 10) ? 'Enter a 10-digit phone number' : null,
                ),
                const SizedBox(height: 16),
                _CityDropdown(
                  value: _city,
                  onChanged: (v) => setState(() => _city = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gstin,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN (optional)',
                    counterText: '',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  validator: (v) => (v != null && v.isNotEmpty && v.trim().length != 15)
                      ? 'GSTIN must be 15 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit for approval'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your store agent reviews and approves new shops before you can sign in.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// City picker limited to serviceable cities; once chosen it confirms the
/// store that will serve the shop (lightweight location verification).
class _CityDropdown extends ConsumerWidget {
  const _CityDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final citiesAsync = ref.watch(serviceCitiesProvider);

    return citiesAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'City',
          prefixIcon: Icon(Icons.location_city_outlined),
        ),
        child: Row(children: [
          SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Loading serviceable cities…'),
        ]),
      ),
      error: (_, __) => TextFormField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          labelText: 'City',
          helperText: 'Couldn’t load cities — type your city',
          prefixIcon: Icon(Icons.location_city_outlined),
        ),
        validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your city' : null,
      ),
      data: (cities) {
        String? storeName;
        for (final c in cities) {
          if (c.city == value) {
            storeName = c.storeName;
            break;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'City',
                helperText: 'Pick the city your shop is in',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: [
                for (final c in cities)
                  DropdownMenuItem(value: c.city, child: Text(c.city)),
              ],
              onChanged: onChanged,
              validator: (v) => (v == null || v.isEmpty) ? 'Select your city' : null,
            ),
            if (storeName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Served by $storeName',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Shown after a successful registration request — the shop waits for the
/// store agent to approve before it can sign in.
class _PendingApprovalScreen extends StatelessWidget {
  const _PendingApprovalScreen({required this.result});
  final RegisterResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('Request submitted',
                  textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
              const SizedBox(height: 12),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              if (result.storeName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 18, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Assigned to ${result.storeName}',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
