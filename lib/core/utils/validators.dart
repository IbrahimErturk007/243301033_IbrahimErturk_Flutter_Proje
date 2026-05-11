import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? required(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.requiredField;
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.requiredField;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(v.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return AppStrings.requiredField;
    if (v.length < 6) return AppStrings.passwordTooShort;
    return null;
  }
}
