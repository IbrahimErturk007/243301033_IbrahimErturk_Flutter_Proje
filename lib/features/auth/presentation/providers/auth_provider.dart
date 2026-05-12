import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/services/log_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../models/profile.dart';

/// Oturum + profil bilgisini tutan ChangeNotifier.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      _refreshProfile();
    });
    _refreshProfile();
  }

  StreamSubscription<sb.AuthState>? _authSub;

  Profile? _profile;
  bool _loading = true;

  Profile? get profile => _profile;
  bool get loading => _loading;
  bool get isAuthenticated => SupabaseService.currentUser != null;
  sb.User? get user => SupabaseService.currentUser;

  Future<void> _refreshProfile() async {
    _loading = true;
    notifyListeners();
    final user = SupabaseService.currentUser;
    if (user == null) {
      _profile = null;
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        _profile = Profile.fromMap(data);
      }
    } catch (e) {
      debugPrint('profile fetch error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final res = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user != null) {
      await LogService.log(action: LogService.actionLogin, details: email);
      await _refreshProfile();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    final res = await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Kayıt başarısız');
    }

    // "Confirm email" açıksa signUp oturum açmaz → auth.uid() null → RLS
    // profil insert'ini reddeder. Bu yüzden önce signIn deneyelim ki
    // session aktif olsun, sonra profili güvenle ekleyelim.
    if (SupabaseService.client.auth.currentSession == null) {
      try {
        await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (_) {
        // signIn başarısızsa (email onay bekliyor olabilir) yine de
        // profil insert deneyeceğiz; başarısız olursa kullanıcı
        // anlaşılır bir hata mesajı görsün.
      }
    }

    try {
      await SupabaseService.client.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'role': role.name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (e) {
      throw Exception(
        'Profil oluşturulamadı: $e\n'
        'Supabase Dashboard → Authentication → Providers → Email '
        'sayfasından "Confirm email" seçeneğini kapatıp tekrar deneyin.',
      );
    }

    await LogService.log(action: LogService.actionRegister, details: email);
    await _refreshProfile();
  }

  /// Kullanıcı giriş yapmış ama `profiles` satırı yoksa (eski hatalı kayıt vs.)
  /// elde olan auth bilgisinden minimal bir profil oluşturmayı dener.
  Future<bool> ensureProfileExists({
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;
    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'role': role.name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      await _refreshProfile();
      return _profile != null;
    } catch (e) {
      debugPrint('ensureProfileExists error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await LogService.log(action: LogService.actionLogout);
    await SupabaseService.client.auth.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<void> reload() => _refreshProfile();

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
