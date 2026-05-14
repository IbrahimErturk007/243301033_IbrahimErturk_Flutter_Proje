import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../models/trip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _loading = true;
  Trip? _activeTrip;
  List<Trip> _history = [];

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
          .from('trips')
          .select()
          .eq('driver_id', uid)
          .order('started_at', ascending: false)
          .limit(20);
      final list = (rows as List)
          .map((e) => Trip.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _activeTrip = list.firstWhere(
        (t) => t.status == TripStatus.active,
        orElse: () => list.isEmpty
            ? Trip(
                id: '',
                driverId: '',
                tripType: TripType.morning,
                status: TripStatus.completed,
              )
            : list.first,
      );
      if (_activeTrip!.id.isEmpty || _activeTrip!.status != TripStatus.active) {
        _activeTrip = null;
      }
      _history = list.where((t) => t.status == TripStatus.completed).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _endTrip(Trip trip) async {
    try {
      await SupabaseService.client.from('trips').update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', trip.id);
      await LogService.log(
          action: LogService.actionTripEnd, details: trip.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sefer bitirildi')),
        );
      }
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
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.driverHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppStrings.logs,
            onPressed: () => context.push('/logs'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: AppStrings.profile,
            onPressed: () => context.push('/driver/profile'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Hoşgeldin, ${auth.profile?.fullName ?? ""}',
                      style:
                          Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_bus,
                                  color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                _activeTrip != null
                                    ? AppStrings.activeTrip
                                    : AppStrings.noActiveTrip,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_activeTrip != null) ...[
                            Text(
                                'Tip: ${_activeTrip!.tripType.tr}'),
                            Text(
                                'Başlangıç: ${_activeTrip!.startedAt != null ? fmt.format(_activeTrip!.startedAt!) : "-"}'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.checklist),
                                    label: const Text(AppStrings.attendance),
                                    onPressed: () => context.push(
                                        '/driver/attendance/${_activeTrip!.id}'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    icon: const Icon(Icons.stop_circle),
                                    label: const Text(AppStrings.endTrip),
                                    onPressed: () => _endTrip(_activeTrip!),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text(AppStrings.startTrip),
                              onPressed: () =>
                                  context.push('/driver/trip/new').then(
                                        (_) => _load(),
                                      ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(AppStrings.tripHistory,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: Text('Henüz tamamlanmış sefer yok')),
                    )
                  else
                    ..._history.map(
                      (t) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text('${t.tripType.tr} Seferi'),
                          subtitle: Text(
                            'Başlangıç: ${t.startedAt != null ? fmt.format(t.startedAt!) : "-"}\n'
                            'Bitiş: ${t.endedAt != null ? fmt.format(t.endedAt!) : "-"}',
                          ),
                          isThreeLine: true,
                          onTap: () =>
                              context.push('/driver/trip/${t.id}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
