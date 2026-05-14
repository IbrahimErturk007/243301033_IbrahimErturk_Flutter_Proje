import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/route_model.dart';
import '../../../../models/trip.dart';

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameCtrl = TextEditingController();
  TripType _type = TripType.morning;
  String? _selectedRouteId;
  bool _loading = false;
  bool _loadingRoutes = true;
  List<RouteModel> _routes = [];

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;
      final data = await SupabaseService.client
          .from('routes')
          .select()
          .eq('driver_id', uid)
          .order('created_at', ascending: false);
      _routes = (data as List)
          .map((e) => RouteModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingRoutes = false);
  }

  @override
  void dispose() {
    _routeNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = SupabaseService.currentUser!.id;
      String routeId = _selectedRouteId ?? '';

      // Yeni güzergah oluşturma
      if (routeId.isEmpty && _routeNameCtrl.text.trim().isNotEmpty) {
        final inserted = await SupabaseService.client.from('routes').insert({
          'route_name': _routeNameCtrl.text.trim(),
          'driver_id': uid,
        }).select().single();
        routeId = inserted['id'] as String;
        await LogService.log(
            action: LogService.actionAddRoute, details: routeId);
      }

      if (routeId.isEmpty) {
        throw Exception('Güzergah seçin veya yeni bir güzergah girin');
      }

      final tripRow = await SupabaseService.client.from('trips').insert({
        'route_id': routeId,
        'driver_id': uid,
        'trip_type': _type.name,
        'status': 'active',
      }).select().single();

      await LogService.log(
          action: LogService.actionTripStart,
          details: 'Trip ${tripRow['id']} - ${_type.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sefer başlatıldı')),
        );
        context.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newTrip)),
      body: _loadingRoutes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_routes.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRouteId,
                        decoration: const InputDecoration(
                          labelText: 'Mevcut Güzergah',
                          prefixIcon: Icon(Icons.alt_route),
                        ),
                        items: _routes
                            .map((r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(r.routeName),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedRouteId = v),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: Text('— veya yeni güzergah —')),
                      ),
                    ],
                    TextFormField(
                      controller: _routeNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Yeni Güzergah Adı',
                        prefixIcon: Icon(Icons.add_road),
                      ),
                      validator: (v) {
                        if (_selectedRouteId != null) return null;
                        return Validators.required(v);
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<TripType>(
                            title: const Text(AppStrings.morning),
                            value: TripType.morning,
                            groupValue: _type,
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                          RadioListTile<TripType>(
                            title: const Text(AppStrings.evening),
                            value: TripType.evening,
                            groupValue: _type,
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _loading ? null : _submit,
                      label: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.startTrip),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
