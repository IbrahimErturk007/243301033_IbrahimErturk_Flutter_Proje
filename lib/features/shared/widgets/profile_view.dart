import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../models/profile.dart';

class ProfileView extends StatelessWidget {
  final Profile? profile;
  final String? email;
  final VoidCallback onLogout;
  final VoidCallback onLogs;

  const ProfileView({
    super.key,
    required this.profile,
    required this.email,
    required this.onLogout,
    required this.onLogs,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              (profile?.fullName.isNotEmpty ?? false)
                  ? profile!.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text(AppStrings.fullName),
                subtitle: Text(profile?.fullName ?? '-'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text(AppStrings.email),
                subtitle: Text(email ?? '-'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text(AppStrings.role),
                subtitle: Text(profile?.role.name == 'driver'
                    ? AppStrings.driver
                    : profile?.role.name == 'parent'
                        ? AppStrings.parent
                        : 'Yönetici'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text(AppStrings.phone),
                subtitle: Text(profile?.phone ?? '-'),
              ),
              if (profile?.createdAt != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Üyelik Tarihi'),
                  subtitle: Text(fmt.format(profile!.createdAt!)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.history),
          label: const Text(AppStrings.logs),
          onPressed: onLogs,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          icon: const Icon(Icons.logout),
          label: const Text(AppStrings.logout),
          onPressed: onLogout,
        ),
      ],
    );
  }
}
