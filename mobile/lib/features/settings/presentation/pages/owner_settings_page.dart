import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Owner-only settings page.
///
/// Note: this is currently a small stub so the app can compile and run while
/// the full owner-settings feature is implemented.
class OwnerSettingsPage extends StatelessWidget {
  const OwnerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final role = authState.user.roleName.toLowerCase();
    if (role != 'owner') {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Owner settings not available for your role')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Owner Settings')),
      body: const Center(child: Text('Owner settings: coming soon')),
    );
  }
}

