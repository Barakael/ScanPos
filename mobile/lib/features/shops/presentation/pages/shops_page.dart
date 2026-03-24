import 'package:flutter/material.dart';

/// Placeholder until shop CRUD is ported from the web app (`/shops`).
class ShopsPage extends StatelessWidget {
  const ShopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shops')),
      body: const Center(
        child: Text(
          'Shop management will mirror the web app in a follow-up.\n'
          'Super admins can use the web console for full CRUD today.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
