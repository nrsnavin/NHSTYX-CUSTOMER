import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';

/// View / edit the shop's business details used on GST tax invoices —
/// legal name, owner, contact email and the 15-character GSTIN.
class GstDetailsScreen extends ConsumerStatefulWidget {
  const GstDetailsScreen({super.key});

  @override
  ConsumerState<GstDetailsScreen> createState() => _GstDetailsScreenState();
}

class _GstDetailsScreenState extends ConsumerState<GstDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopName;
  late final TextEditingController _ownerName;
  late final TextEditingController _email;
  late final TextEditingController _gstin;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = ref.read(authControllerProvider).valueOrNull;
    _shopName = TextEditingController(text: c?.shopName ?? '');
    _ownerName = TextEditingController(text: c?.ownerName ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _gstin = TextEditingController(text: c?.gstin ?? '');
  }

  @override
  void dispose() {
    for (final c in [_shopName, _ownerName, _email, _gstin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            shopName: _shopName.text.trim(),
            ownerName: _ownerName.text.trim(),
            email: _email.text.trim(),
            gstin: _gstin.text.trim().toUpperCase(),
          );
      await ref.read(authControllerProvider.notifier).refreshProfile();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Business details saved')));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('GST & business details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'These details appear on your GST tax invoices. Add a valid '
                  'GSTIN to claim input tax credit on your orders.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 20),
                _field(_shopName, 'Shop / business name', validator: _required),
                _field(_ownerName, 'Owner name (optional)'),
                _field(
                  _email,
                  'Email (optional)',
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(
                  _gstin,
                  'GSTIN (15 characters)',
                  textCapitalization: TextCapitalization.characters,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(15),
                    _UpperCaseFormatter(),
                  ],
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null; // GSTIN is optional
                    return t.length == 15 ? null : 'GSTIN must be exactly 15 characters';
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: formatters,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }
}

/// Keeps GSTIN upper-cased as the user types.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
