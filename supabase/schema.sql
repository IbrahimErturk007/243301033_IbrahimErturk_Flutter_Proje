-- ============================================================
-- Okul Servis Yoklama ve Sefer Sistemi - Supabase Schema
-- ============================================================
-- Bu dosyay─▒ Supabase Dashboard > SQL Editor ├╝zerinden ├ğal─▒┼şt─▒r─▒n.
-- ============================================================

-- UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1) PROFILES (Kullan─▒c─▒ profilleri - auth.users'a ba─şl─▒)
-- ============================================================
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    role text not null check (role in ('driver', 'parent', 'admin')),
    phone text,
    created_at timestamp default (now() at time zone 'Europe/Istanbul')
);

-- ============================================================
-- 2) ROUTES (Servis g├╝zerg├óhlar─▒)
-- ============================================================
create table if not exists public.routes (
    id uuid primary key default uuid_generate_v4(),
    route_name text not null,
    driver_id uuid references public.profiles(id) on delete set null,
    created_at timestamp default (now() at time zone 'Europe/Istanbul')
);

-- ============================================================
-- 3) STUDENTS (├û─şrenciler)
-- ============================================================
create table if not exists public.students (
    id uuid primary key default uuid_generate_v4(),
    full_name text not null,
    parent_id uuid references public.profiles(id) on delete cascade,
    route_id uuid references public.routes(id) on delete set null,
    school_no text,
    created_at timestamp default (now() at time zone 'Europe/Istanbul')
);

-- ============================================================
-- 4) TRIPS (Seferler)
-- ============================================================
create table if not exists public.trips (
    id uuid primary key default uuid_generate_v4(),
    route_id uuid references public.routes(id) on delete set null,
    driver_id uuid references public.profiles(id) on delete set null,
    trip_type text not null check (trip_type in ('morning', 'evening')),
    status text not null default 'active' check (status in ('active', 'completed')),
    started_at timestamp default (now() at time zone 'Europe/Istanbul'),
    ended_at timestamp
);

-- ============================================================
-- 5) ATTENDANCE (Yoklama kay─▒tlar─▒)
-- ============================================================
create table if not exists public.attendance (
    id uuid primary key default uuid_generate_v4(),
    trip_id uuid references public.trips(id) on delete cascade,
    student_id uuid references public.students(id) on delete cascade,
    status text not null check (status in ('boarded', 'dropped', 'absent')),
    timestamp timestamp default (now() at time zone 'Europe/Istanbul')
);

-- ============================================================
-- 6) LOGS (─░┼şlem loglar─▒)
-- ============================================================
create table if not exists public.logs (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references public.profiles(id) on delete set null,
    action text not null,
    details text,
    created_at timestamp default (now() at time zone 'Europe/Istanbul')
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.profiles enable row level security;
alter table public.routes enable row level security;
alter table public.students enable row level security;
alter table public.trips enable row level security;
alter table public.attendance enable row level security;
alter table public.logs enable row level security;

-- PROFILES policies
-- Not: Kendi tablosuna referans veren EXISTS sonsuz döngüye yol açar
-- (Supabase'de "infinite recursion detected" hatası). Bu yüzden basit
-- "authenticated" kontrolü kullanıyoruz.
drop policy if exists "profiles_select_self_or_driver" on public.profiles;
drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
on public.profiles for select
using (auth.role() = 'authenticated');

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles for update
using (auth.uid() = id);

-- ROUTES policies
drop policy if exists "routes_select_all" on public.routes;
create policy "routes_select_all"
on public.routes for select
using (auth.role() = 'authenticated');

drop policy if exists "routes_insert_driver" on public.routes;
create policy "routes_insert_driver"
on public.routes for insert
with check (
    exists (select 1 from public.profiles p
            where p.id = auth.uid() and p.role in ('driver','admin'))
);

drop policy if exists "routes_update_driver" on public.routes;
create policy "routes_update_driver"
on public.routes for update
using (driver_id = auth.uid());

-- STUDENTS policies
drop policy if exists "students_select_parent_or_driver" on public.students;
create policy "students_select_parent_or_driver"
on public.students for select
using (
    parent_id = auth.uid()
    or exists (select 1 from public.profiles p
               where p.id = auth.uid() and p.role in ('driver','admin'))
);

drop policy if exists "students_insert_parent" on public.students;
create policy "students_insert_parent"
on public.students for insert
with check (parent_id = auth.uid());

drop policy if exists "students_update_parent" on public.students;
create policy "students_update_parent"
on public.students for update
using (parent_id = auth.uid());

drop policy if exists "students_delete_parent" on public.students;
create policy "students_delete_parent"
on public.students for delete
using (parent_id = auth.uid());

-- TRIPS policies
drop policy if exists "trips_select_all_auth" on public.trips;
create policy "trips_select_all_auth"
on public.trips for select
using (auth.role() = 'authenticated');

drop policy if exists "trips_insert_driver" on public.trips;
create policy "trips_insert_driver"
on public.trips for insert
with check (driver_id = auth.uid());

drop policy if exists "trips_update_driver" on public.trips;
create policy "trips_update_driver"
on public.trips for update
using (driver_id = auth.uid());

-- ATTENDANCE policies
drop policy if exists "attendance_select_related" on public.attendance;
create policy "attendance_select_related"
on public.attendance for select
using (
    exists (select 1 from public.profiles p
            where p.id = auth.uid() and p.role in ('driver','admin'))
    or exists (select 1 from public.students s
               where s.id = attendance.student_id and s.parent_id = auth.uid())
);

drop policy if exists "attendance_insert_driver" on public.attendance;
create policy "attendance_insert_driver"
on public.attendance for insert
with check (
    exists (select 1 from public.profiles p
            where p.id = auth.uid() and p.role in ('driver','admin'))
);

-- LOGS policies
drop policy if exists "logs_select_self" on public.logs;
create policy "logs_select_self"
on public.logs for select
using (user_id = auth.uid());

drop policy if exists "logs_insert_self" on public.logs;
create policy "logs_insert_self"
on public.logs for insert
with check (user_id = auth.uid());
