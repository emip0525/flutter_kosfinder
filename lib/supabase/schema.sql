-- =====================================================================
-- WORKSHEET 9: Authentication, Authorization & Push Notifications
-- Database Schema, RLS Policies & Dummy Data
-- Kasus: KosFinder (Pencari Kos, Pemilik Kos, Admin)
-- Mahasiswa: Miftah Fadilatus Sakhila (2415051011) - PTI 5A
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TABEL PROFILES (Role-Based Authorization: Seeker, Owner, Admin)
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'seeker' check (role in ('seeker', 'owner', 'admin'))
);

alter table public.profiles enable row level security;

-- Policy Profiles: Semua user yang login dapat membaca profile dasar
create policy "profiles_select_all"
  on public.profiles for select to authenticated
  using (true);

-- Policy Profiles: User hanya bisa mengubah profil miliknya sendiri
create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Function & Trigger: Otomatis mengisi profiles saat akun mendaftar (auth.signUp)
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
    coalesce(new.raw_user_meta_data->>'name', 'Pengguna KosFinder'),
    case
      when new.raw_user_meta_data->>'role' in ('seeker', 'owner', 'admin')
        then new.raw_user_meta_data->>'role'
      else 'seeker'
    end
  )
  on conflict (id) do update set
    name = excluded.name,
    role = excluded.role;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Helper function: Memeriksa apakah user yang sedang login adalah Admin
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
-- 2. TABEL KOS (Data Ownership, Foto Tampak Luar/Dalam & WhatsApp)
-- ---------------------------------------------------------------------
create table if not exists public.kos (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  address text,
  price integer default 0,
  facilities text default 'WiFi, Kamar Mandi Dalam, Kasur, Lemari',
  description text default '',
  exterior_image_url text, -- Foto Tampak Luar (Gedung)
  interior_image_url text, -- Foto Tampak Dalam (Kamar)
  owner_whatsapp text,     -- Kontak WhatsApp Pemilik Kos
  is_verified boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.kos enable row level security;

-- Policy 1: SELECT (Semua pengguna login dapat membaca dan mencari daftar kos)
create policy "kos_select_authenticated"
  on public.kos for select to authenticated
  using (true);

-- Policy 2: INSERT (Hanya Pemilik Kos atau Admin yang boleh menambah kos)
create policy "kos_insert_owner"
  on public.kos for insert to authenticated
  with check (
    auth.uid() = owner_id
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('owner', 'admin')
    )
  );

-- Policy 3: UPDATE (Hanya pemilik kos atau admin yang boleh mengubah data)
create policy "kos_update_own"
  on public.kos for update to authenticated
  using (auth.uid() = owner_id or public.is_admin())
  with check (auth.uid() = owner_id or public.is_admin());

-- Policy 4: DELETE (Hanya pemilik kos atau admin yang boleh menghapus)
create policy "kos_delete_own"
  on public.kos for delete to authenticated
  using (auth.uid() = owner_id or public.is_admin());

-- ---------------------------------------------------------------------
-- 3. TABEL DEVICE_TOKENS (Push Notification FCM Device Registration)
-- ---------------------------------------------------------------------
create table if not exists public.device_tokens (
  token text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  platform text,
  updated_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

create policy "tokens_select_own" on public.device_tokens
  for select to authenticated using (auth.uid() = user_id or public.is_admin());

create policy "tokens_insert_own" on public.device_tokens
  for insert to authenticated with check (auth.uid() = user_id);

create policy "tokens_update_own" on public.device_tokens
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "tokens_delete_own" on public.device_tokens
  for delete to authenticated using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 4. CONTOH SEED DATA (Opsional: Properti Kos Awal)
-- ---------------------------------------------------------------------
-- Note: Jalankan setelah membuat user Owner di Authentication > Users
-- insert into public.kos (name, address, price, facilities, description, exterior_image_url, interior_image_url, owner_whatsapp, is_verified)
-- values
-- ('Kos Graha Undiksha Asri', 'Jl. Udayana No. 11, Singaraja, Bali', 850000, 'WiFi Cepat, AC, Kamar Mandi Dalam', 'Kos nyaman khusus mahasiswa dekat kampus.', 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800', 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800', '6281234567890', true),
-- ('Kos Melati Harmoni', 'Jl. Ahmad Yani Gg. Remaja No. 4, Singaraja', 650000, 'WiFi, Kamar Mandi Dalam, Kasur', 'Kos bersih sirkulasi udara baik.', 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800', '6281234567890', false);
