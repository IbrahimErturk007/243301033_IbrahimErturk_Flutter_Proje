import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../models/attendance.dart';
import '../../../../models/trip.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  List<Attendance> _records = [];
  Map<String, String> _studentNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await SupabaseService.client
          .from('trips')
          .select()
          .eq('id', widget.tripId)
          .single();
      _trip = Trip.fromMap(Map<String, dynamic>.from(t));

      final att = await SupabaseService.client
          .from('attendance')
          .select()
          .eq('trip_id', widget.tripId)
          .order('timestamp', ascending: true);
      _records = (att as List)
          .map((e) => Attendance.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (_records.isNotEmpty) {
        final ids = _records.map((e) => e.studentId).toSet().toList();
        final stud = await SupabaseService.client
            .from('students')
            .select('id, full_name')
            .inFilter('id', ids);
        _studentNames = {
          for (final s in (stud as List))
            s['id'] as String: s['full_name'] as String? ?? '-'
        };
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sefer Detayı')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trip == null
              ? const Center(child: Text('Sefer bulunamadı'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tip: ${_trip!.tripType.tr}'),
                            Text('Durum: ${_trip!.status.name}'),
                            Text(
                                'Başlangıç: ${_trip!.startedAt != null ? fmt.format(_trip!.startedAt!) : "-"}'),
                            Text(
                                'Bitiş: ${_trip!.endedAt != null ? fmt.format(_trip!.endedAt!) : "-"}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Yoklama Kayıtları (${_records.length})',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_records.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('Yoklama kaydı yok')),
                      )
                    else
                      ..._records.map((r) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: r.status ==
                                        AttendanceStatus.boarded
                                    ? Colors.green
                                    : r.status == AttendanceStatus.dropped
                                        ? Colors.blue
                                        : Colors.red,
                                child: Icon(
                                    r.status == AttendanceStatus.boarded
                                        ? Icons.login
                                        : r.status == AttendanceStatus.dropped
                                            ? Icons.logout
                                            : Icons.cancel,
                                    color: Colors.white),
                              ),
                              title: Text(_studentNames[r.studentId] ??
                                  r.studentId),
                              subtitle: Text(
                                  '${r.status.tr} • ${r.timestamp != null ? fmt.format(r.timestamp!) : "-"}'),
                            ),
                          )),
                  ],
                ),
    );
  }
}
