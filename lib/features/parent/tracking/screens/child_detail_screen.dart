import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../models/attendance.dart';
import '../../../../models/student.dart';

class ChildDetailScreen extends StatefulWidget {
  final String studentId;
  const ChildDetailScreen({super.key, required this.studentId});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  bool _loading = true;
  Student? _student;
  List<Attendance> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await SupabaseService.client
          .from('students')
          .select()
          .eq('id', widget.studentId)
          .single();
      _student = Student.fromMap(Map<String, dynamic>.from(s));

      final att = await SupabaseService.client
          .from('attendance')
          .select()
          .eq('student_id', widget.studentId)
          .order('timestamp', ascending: false)
          .limit(50);
      _records = (att as List)
          .map((e) => Attendance.fromMap(Map<String, dynamic>.from(e)))
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

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    final today = DateTime.now();
    final todays = _records.where((r) =>
        r.timestamp != null &&
        r.timestamp!.year == today.year &&
        r.timestamp!.month == today.month &&
        r.timestamp!.day == today.day).toList();

    return Scaffold(
      appBar: AppBar(title: Text(_student?.fullName ?? 'Detay')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bugünkü Durum',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (todays.isEmpty)
                            const Text('Bugün için yoklama kaydı yok.')
                          else
                            ...todays.map((r) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        r.status == AttendanceStatus.boarded
                                            ? Icons.login
                                            : r.status ==
                                                    AttendanceStatus.dropped
                                                ? Icons.logout
                                                : Icons.cancel,
                                        color: r.status ==
                                                AttendanceStatus.boarded
                                            ? Colors.green
                                            : r.status ==
                                                    AttendanceStatus.dropped
                                                ? Colors.blue
                                                : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${r.status.tr} • ${fmt.format(r.timestamp!)}'),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Geçmiş Kayıtlar (${_records.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Geçmiş kayıt yok')),
                    )
                  else
                    ..._records.map((r) => Card(
                          child: ListTile(
                            leading: Icon(
                              r.status == AttendanceStatus.boarded
                                  ? Icons.login
                                  : r.status == AttendanceStatus.dropped
                                      ? Icons.logout
                                      : Icons.cancel,
                              color: r.status == AttendanceStatus.boarded
                                  ? Colors.green
                                  : r.status == AttendanceStatus.dropped
                                      ? Colors.blue
                                      : Colors.red,
                            ),
                            title: Text(r.status.tr),
                            subtitle: Text(r.timestamp != null
                                ? fmt.format(r.timestamp!)
                                : '-'),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
