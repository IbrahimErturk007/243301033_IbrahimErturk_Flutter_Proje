import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/log_entry.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  bool _loading = true;
  List<LogEntry> _logs = [];

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
          .from('logs')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(200);
      _logs = (rows as List)
          .map((e) => LogEntry.fromMap(Map<String, dynamic>.from(e)))
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

  IconData _iconFor(String action) {
    switch (action) {
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'REGISTER':
        return Icons.person_add;
      case 'TRIP_START':
        return Icons.play_circle;
      case 'TRIP_END':
        return Icons.stop_circle;
      case 'ATTENDANCE_MARK':
        return Icons.checklist;
      case 'ADD_STUDENT':
        return Icons.person_add_alt;
      case 'EDIT_STUDENT':
        return Icons.edit;
      case 'DELETE_STUDENT':
        return Icons.person_remove;
      case 'ADD_ROUTE':
        return Icons.alt_route;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm:ss');
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.logs)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('Henüz log kaydı yok'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (ctx, i) {
                      final l = _logs[i];
                      return ListTile(
                        leading: Icon(_iconFor(l.action)),
                        title: Text(l.action),
                        subtitle: Text(
                          [
                            if (l.details != null) l.details!,
                            l.createdAt != null ? fmt.format(l.createdAt!) : '',
                          ].where((e) => e.isNotEmpty).join(' • '),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
