import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../models/attendance.dart';
import '../../../../models/student.dart';
import '../../../../models/trip.dart';

class AttendanceScreen extends StatefulWidget {
  final String tripId;
  const AttendanceScreen({super.key, required this.tripId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _loading = true;
  Trip? _trip;
  List<Student> _students = [];
  // student_id -> latest status
  final Map<String, AttendanceStatus> _current = {};

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

      // Bu güzergahtaki öğrenciler
      List<Student> students = [];
      if (_trip!.routeId != null) {
        final rows = await SupabaseService.client
            .from('students')
            .select()
            .eq('route_id', _trip!.routeId!)
            .order('full_name');
        students = (rows as List)
            .map((e) => Student.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      _students = students;

      // Mevcut yoklamalar
      final att = await SupabaseService.client
          .from('attendance')
          .select()
          .eq('trip_id', widget.tripId)
          .order('timestamp', ascending: true);
      for (final r in (att as List)) {
        final a = Attendance.fromMap(Map<String, dynamic>.from(r));
        _current[a.studentId] = a.status;
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

  Future<void> _mark(Student s, AttendanceStatus status) async {
    try {
      await SupabaseService.client.from('attendance').insert({
        'trip_id': widget.tripId,
        'student_id': s.id,
        'status': status.name,
      });
      await LogService.log(
        action: LogService.actionAttendance,
        details: 'Trip ${widget.tripId} - ${s.fullName}: ${status.name}',
      );

      // Bildirim
      await NotificationService.show(
        title: 'Yoklama Güncellendi',
        body: '${s.fullName}: ${status.tr}',
      );

      setState(() => _current[s.id] = status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.fullName}: ${status.tr}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Color _statusColor(AttendanceStatus? s) {
    switch (s) {
      case AttendanceStatus.boarded:
        return Colors.green;
      case AttendanceStatus.dropped:
        return Colors.blue;
      case AttendanceStatus.absent:
        return Colors.red;
      case null:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.attendance)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Bu güzergahta kayıtlı öğrenci yok.\n\n'
                      'Veliler çocuklarını ekledikten sonra burada görünecek.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _students.length,
                    itemBuilder: (ctx, i) {
                      final s = _students[i];
                      final status = _current[s.id];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _statusColor(status),
                                    child: Text(
                                      s.fullName.isNotEmpty
                                          ? s.fullName[0].toUpperCase()
                                          : '?',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s.fullName,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold)),
                                        if (s.schoolNo != null)
                                          Text('No: ${s.schoolNo}'),
                                        if (status != null)
                                          Text('Durum: ${status.tr}',
                                              style: TextStyle(
                                                  color: _statusColor(status))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.login,
                                          color: Colors.green),
                                      label: const Text(AppStrings.boarded),
                                      onPressed: () =>
                                          _mark(s, AttendanceStatus.boarded),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.logout,
                                          color: Colors.blue),
                                      label: const Text(AppStrings.dropped),
                                      onPressed: () =>
                                          _mark(s, AttendanceStatus.dropped),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.red),
                                      label: const Text(AppStrings.absent),
                                      onPressed: () =>
                                          _mark(s, AttendanceStatus.absent),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
