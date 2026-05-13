import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/route_model.dart';

class ChildFormScreen extends StatefulWidget {
  final String? childId;
  const ChildFormScreen({super.key, this.childId});

  bool get isEdit => childId != null;

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _schoolNoCtrl = TextEditingController();
  String? _selectedRouteId;
  List<RouteModel> _routes = [];
  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    try {
      // Tüm güzergahları çek
      final r = await SupabaseService.client
          .from('routes')
          .select()
          .order('route_name');
      _routes = (r as List)
          .map((e) => RouteModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Düzenleme modunda mevcut veriyi yükle
      if (widget.isEdit) {
        final data = await SupabaseService.client
            .from('students')
            .select()
            .eq('id', widget.childId!)
            .single();
        _nameCtrl.text = data['full_name'] ?? '';
        _schoolNoCtrl.text = data['school_no'] ?? '';
        _selectedRouteId = data['route_id'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = SupabaseService.currentUser!.id;
      final payload = {
        'full_name': _nameCtrl.text.trim(),
        'parent_id': uid,
        'route_id': _selectedRouteId,
        'school_no': _schoolNoCtrl.text.trim().isEmpty
            ? null
            : _schoolNoCtrl.text.trim(),
      };

      if (widget.isEdit) {
        await SupabaseService.client
            .from('students')
            .update(payload)
            .eq('id', widget.childId!);
        await LogService.log(
            action: LogService.actionEditStudent,
            details: _nameCtrl.text.trim());
      } else {
        await SupabaseService.client.from('students').insert(payload);
        await LogService.log(
            action: LogService.actionAddStudent,
            details: _nameCtrl.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedildi')),
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
      appBar: AppBar(
        title: Text(widget.isEdit ? AppStrings.editChild : AppStrings.addChild),
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.childName,
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _schoolNoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: AppStrings.schoolNo,
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_routes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                            'Henüz bir güzergah tanımlı değil. Şoför güzergah eklediğinde seçebilirsiniz.',
                            style: TextStyle(color: Colors.orange)),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRouteId,
                        decoration: const InputDecoration(
                          labelText: 'Güzergah',
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
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.save),
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
                          : const Text(AppStrings.save),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
