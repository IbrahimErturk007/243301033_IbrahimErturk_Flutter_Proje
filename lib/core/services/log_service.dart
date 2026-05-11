import 'supabase_service.dart';

/// Tüm kritik kullanıcı işlemlerini `logs` tablosuna yazan servis.
class LogService {
  LogService._();

  static Future<void> log({
    required String action,
    String? details,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;
      await SupabaseService.client.from('logs').insert({
        'user_id': user.id,
        'action': action,
        'details': details,
      });
    } catch (e) {
      // Log yazılamazsa uygulamayı çökertme - sessizce geç.
      // ignore: avoid_print
      print('LogService error: $e');
    }
  }

  // İşlem tipleri için sabitler
  static const actionLogin = 'LOGIN';
  static const actionLogout = 'LOGOUT';
  static const actionRegister = 'REGISTER';
  static const actionTripStart = 'TRIP_START';
  static const actionTripEnd = 'TRIP_END';
  static const actionAttendance = 'ATTENDANCE_MARK';
  static const actionAddStudent = 'ADD_STUDENT';
  static const actionEditStudent = 'EDIT_STUDENT';
  static const actionDeleteStudent = 'DELETE_STUDENT';
  static const actionAddRoute = 'ADD_ROUTE';
}
