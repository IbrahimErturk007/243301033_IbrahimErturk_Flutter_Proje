-- ============================================================
-- profiles policy'sindeki sonsuz döngü düzeltmesi
-- Supabase Dashboard → SQL Editor'da çalıştır
-- ============================================================

-- Hatalı (kendine referans veren) policy'yi kaldır
drop policy if exists "profiles_select_self_or_driver" on public.profiles;

-- Yerine basit, recursion'sız policy: tüm authenticated kullanıcılar
-- profilleri okuyabilir (şoförün veliyi, velinin kendi çocuğunun
-- şoförünü görmesi için zaten gerekiyor)
create policy "profiles_select_authenticated"
on public.profiles for select
using (auth.role() = 'authenticated');
