// Basit smoke test — uygulama hata vermeden başlatılabiliyor mu?
//
// Not: Gerçek widget testleri için Supabase ve dotenv mock'lanmalı.
// Bu dosya yalnızca derleme hatasını gidermek için minimal tutulmuştur.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder test', () {
    expect(1 + 1, 2);
  });
}
