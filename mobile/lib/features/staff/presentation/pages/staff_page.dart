import 'package:flutter/material.dart';

/// Placeholder until staff CRUD is ported from the web app (`/staff`).
class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: const Center(
        child: Text(
          'Staff management will mirror the web app in a follow-up.\n'
          'Owners can use the web console for full CRUD today.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
