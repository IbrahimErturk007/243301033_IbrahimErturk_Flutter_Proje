import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../models/student.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  bool _loading = true;
  List<Student> _children = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;
      final rows = await SupabaseService.client
          .from('students')
          .select()
          .eq('parent_id', uid)
          .order('full_name');
      _children = (rows as List)
          .map((e) => Student.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: Text('${s.fullName} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService.client.from('students').delete().eq('id', s.id);
      await LogService.log(
        action: LogService.actionDeleteStudent,
        details: s.fullName,
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.parentHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppStrings.logs,
            onPressed: () => context.push('/logs'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: AppStrings.profile,
            onPressed: () => context.push('/parent/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/parent/child/new').then((_) => _load()),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addChild),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Hoşgeldiniz, ${auth.profile?.fullName ?? ""}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text(AppStrings.myChildren,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_children.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Henüz çocuk eklenmedi.\nSağ alttaki + ile ekleyin.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._children.map((s) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(s.fullName.isNotEmpty
                                  ? s.fullName[0].toUpperCase()
                                  : '?'),
                            ),
                            title: Text(s.fullName),
                            subtitle: Text(s.schoolNo != null
                                ? 'Okul No: ${s.schoolNo}'
                                : 'Detayları görmek için tıkla'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') {
                                  context
                                      .push('/parent/child/edit/${s.id}')
                                      .then((_) => _load());
                                } else if (v == 'delete') {
                                  _delete(s);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Düzenle')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Sil')),
                              ],
                            ),
                            onTap: () =>
                                context.push('/parent/child/${s.id}'),
                          ),
                        )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
