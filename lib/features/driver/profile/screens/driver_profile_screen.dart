import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/profile_view.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ProfileView(
        profile: auth.profile,
        email: auth.user?.email,
        onLogout: () async {
          await auth.signOut();
          if (context.mounted) context.go('/login');
        },
        onLogs: () => context.push('/logs'),
      ),
    );
  }
}
