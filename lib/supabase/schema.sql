-- =====================================================================
-- WORKSHEET 9: Authentication, Authorization & Push Notifications
-- Database Schema & Row Level Security (RLS) Policies
-- Studi Kasus: KosFinder
-- Mahasiswa: Miftah Fadilatus Sakhila (2415051011) - PTI 5A
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TABEL PROFILES (Role-Based Authorization)
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'seeker' check (role in ('seeker', 'owner', 'admin'))
);

alter table public.profiles enable row level security;

-- Policy Profiles: Pengguna hanya boleh membaca profil miliknya sendiri
create policy "profiles_select_own"
  on public.profiles for select to authenticated
  using (auth.uid() = id);

-- Function & Trigger: Otomatis membuat profile saat user mendaftar (auth.signUp)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    case
      when new.raw_user_meta_data->>'role' in ('seeker', 'owner')
        then new.raw_user_meta_data->>'role'
      else 'seeker'
    end
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Helper function: cek apakah user saat ini adalah admin
create or replace function public.is_admin()
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------
-- 2. TABEL KOS (Data Ownership & Row Level Security)
-- ---------------------------------------------------------------------
create table if not exists public.kos (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  address text,
  price integer default 0,
  facilities text default 'WiFi, Kamar Mandi Dalam',
  description text default '',
  created_at timestamptz not null default now()
);

alter table public.kos enable row level security;

-- Policy 1: SELECT - Semua authenticated user dapat membaca katalog kos
create policy "kos_select_authenticated"
  on public.kos for select to authenticated
  using (true);

-- Policy 2: INSERT - Hanya pengguna dengan role 'owner' atau 'admin' yang dapat menambah kos
create policy "kos_insert_owner"
  on public.kos for insert to authenticated
  with check (
    auth.uid() = owner_id
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('owner', 'admin')
    )
  );

-- Policy 3: UPDATE - Hanya pemilik kos (owner_id = auth.uid()) yang dapat mengubah kos miliknya
create policy "kos_update_own"
  on public.kos for update to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Policy 4: DELETE - Hanya pemilik kos yang dapat menghapus kos miliknya
create policy "kos_delete_own"
  on public.kos for delete to authenticated
  using (auth.uid() = owner_id);

-- Policy 5: ADMIN ALL - Admin memiliki wewenang penuh atas seluruh baris kos
create policy "kos_admin_all"
  on public.kos for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------
-- 3. TABEL DEVICE_TOKENS (Push Notification Device Registration)
-- ---------------------------------------------------------------------
create table if not exists public.device_tokens (
  token text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  platform text,
  updated_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

create policy "tokens_select_own" on public.device_tokens
  for select to authenticated using (auth.uid() = user_id);

create policy "tokens_insert_own" on public.device_tokens
  for insert to authenticated with check (auth.uid() = user_id);

create policy "tokens_update_own" on public.device_tokens
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "tokens_delete_own" on public.device_tokens
  for delete to authenticated using (auth.uid() = user_id);
