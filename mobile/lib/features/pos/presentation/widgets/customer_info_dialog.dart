import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Customer details for TRA legal receipt (prefilled with demo sample values).
class CustomerInfo {
  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.idType,
    required this.idNumber,
  });

  final String name;
  final String phone;
  final String address;
  final String idType;
  final String idNumber;
}

class CustomerInfoDialog extends StatefulWidget {
  const CustomerInfoDialog({super.key});

  @override
  State<CustomerInfoDialog> createState() => _CustomerInfoDialogState();
}

class _CustomerInfoDialogState extends State<CustomerInfoDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _idType;
  late final TextEditingController _idNumber;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: 'SALEHE DUMMY');
    _phone = TextEditingController(text: '+255744861601');
    _address = TextEditingController(text: 'DODOMA');
    _idType = TextEditingController();
    _idNumber = TextEditingController(text: '+255744861601');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _idType.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, phone and address are required.')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(CustomerInfo(
      name: name,
      phone: phone,
      address: address,
      idType: _idType.text.trim(),
      idNumber: _idNumber.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1E3A5F);
    return AlertDialog(
      title: const Text('Customer (TRA receipt)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Mobile number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _idType,
              decoration: const InputDecoration(
                labelText: 'ID type (optional)',
              ),
            ),
            TextField(
              controller: _idNumber,
              decoration: const InputDecoration(
                labelText: 'Customer ID (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: primary),
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
