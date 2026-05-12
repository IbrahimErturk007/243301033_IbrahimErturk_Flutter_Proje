import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../models/profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;
  bool _showRecover = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await auth.reload();
    if (!mounted) return;

    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }

    // Profil yüklenene kadar bekle
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final p = auth.profile;
    if (p == null) {
      // Profil oluşturulmamış → kullanıcıyı login'e atmak yerine
      // burada ne olduğunu açıkla, "Profili Oluştur" seçeneği sun.
      setState(() {
        _error =
            'Hesap mevcut ama profiles tablosunda profil bulunamadı. '
            'Bunun sebebi genelde Supabase\'de "Confirm email" açık olduğu '
            'için kayıt sırasında profil eklenememesidir.';
        _showRecover = true;
      });
      return;
    }
    if (p.role == UserRole.driver) {
      context.go('/driver');
    } else {
      context.go('/parent');
    }
  }

  Future<void> _recoverProfile(UserRole role) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    final defaultName =
        (user.email ?? 'Kullanıcı').split('@').first;
    final ok = await auth.ensureProfileExists(
      fullName: defaultName,
      role: role,
    );
    if (!mounted) return;
    if (ok) {
      // Doğrudan rolüne göre yönlendir
      context.go(role == UserRole.driver ? '/driver' : '/parent');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profil oluşturulamadı. Supabase Dashboard → SQL Editor\'dan '
            'schema.sql\'i çalıştırdığınızdan ve "Confirm email"\'in '
            'kapalı olduğundan emin olun.',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Icon(Icons.directions_bus,
                    size: 96,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                const Text(
                  AppStrings.appName,
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_error == null) ...[
                  const CircularProgressIndicator(),
                ] else ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  if (_showRecover) ...[
                    const Text(
                      'Hangi rolle devam etmek istersiniz?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _recoverProfile(UserRole.driver),
                      icon: const Icon(Icons.directions_bus),
                      label: const Text('Şoför olarak devam et'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _recoverProfile(UserRole.parent),
                      icon: const Icon(Icons.family_restroom),
                      label: const Text('Veli olarak devam et'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _logout,
                      child: const Text('Çıkış yap'),
                    ),
                  ],
                ],
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
