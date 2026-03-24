import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is! AuthAuthenticated) return const SizedBox.shrink();
              final user = state.user;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withAlpha(25),
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(color: AppColors.grey500),
                            ),
                            Text(
                              user.roleName,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Change Password
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ),
          const SizedBox(height: 8),

          // About
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Tera POS'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Tera POS',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        '© 2026 Tera Tech. All rights reserved.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          AppButton(
            label: 'Sign Out',
            isOutlined: true,
            color: AppColors.error,
            onPressed: () => context
                .read<AuthBloc>()
                .add(const AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: currentCtrl,
                label: 'Current Password',
                obscureText: true,
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: newCtrl,
                label: 'New Password',
                obscureText: true,
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: confirmCtrl,
                label: 'Confirm New Password',
                obscureText: true,
                validator: (v) =>
                    Validators.confirmPassword(v, newCtrl.text),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthPasswordChanged) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) => TextButton(
              onPressed: state is AuthLoading
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                              AuthChangePasswordRequested(
                                currentPassword: currentCtrl.text,
                                newPassword: newCtrl.text,
                              ),
                            );
                      }
                    },
              child: state is AuthLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
