-- QR Forge — Café Ordering System
-- Run this once in your Supabase project's SQL editor.
-- Safe to re-run: uses "if not exists" / "on conflict do nothing" where possible.

create extension if not exists pgcrypto;

-- ── Settings (single row, editable from admin) ──────────────────────────────
create table if not exists settings (
  id int primary key default 1,
  restaurant_name text not null default 'Your Restaurant',
  logo_url text,
  accent_color text not null default '#F2B705',
  constraint single_row check (id = 1)
);
insert into settings (id) values (1) on conflict (id) do nothing;

-- ── Menu ─────────────────────────────────────────────────────────────────
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort_order int not null default 0
);

create table if not exists menu_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references categories(id) on delete set null,
  name text not null,
  description text default '',
  price numeric(10,2) not null default 0,
  image_url text,
  is_available boolean not null default true,
  -- customizations shape:
  -- [{"name":"Size","type":"single","options":[{"label":"Regular","delta":0},{"label":"Large","delta":40}]}]
  customizations jsonb not null default '[]'::jsonb,
  sort_order int not null default 0
);

-- ── Tables (one row per physical table, each with its own QR token) ────────
create table if not exists tables (
  id uuid primary key default gen_random_uuid(),
  table_number int not null unique,
  qr_token text not null unique default encode(gen_random_bytes(6), 'hex')
);

-- ── Orders ───────────────────────────────────────────────────────────────
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  table_id uuid references tables(id),
  status text not null default 'pending'
    check (status in ('pending','preparing','ready','served','cancelled')),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid','paid')),
  subtotal numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  customer_note text default '',
  created_at timestamptz not null default now()
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  menu_item_id uuid references menu_items(id),
  item_name text not null,
  quantity int not null default 1,
  unit_price numeric(10,2) not null,
  customizations jsonb not null default '[]'::jsonb,
  line_total numeric(10,2) not null
);

-- ── Row Level Security ───────────────────────────────────────────────────
alter table settings enable row level security;
alter table categories enable row level security;
alter table menu_items enable row level security;
alter table tables enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

-- Public (anon) can read menu/settings/tables — needed for customers to browse
drop policy if exists "public read settings" on settings;
create policy "public read settings" on settings for select using (true);

drop policy if exists "public read categories" on categories;
create policy "public read categories" on categories for select using (true);

drop policy if exists "public read menu_items" on menu_items;
create policy "public read menu_items" on menu_items for select using (true);

drop policy if exists "public read tables" on tables;
create policy "public read tables" on tables for select using (true);

-- Public (anon) can create orders and read order status
-- NOTE: this also means any anon key holder can read ALL orders, not just their
-- own — Postgres RLS cannot restrict by "the id you happen to know". Acceptable
-- for a demo; do not use this policy as-is for a business handling real revenue.
drop policy if exists "public insert orders" on orders;
create policy "public insert orders" on orders for insert with check (true);

drop policy if exists "public select orders" on orders;
create policy "public select orders" on orders for select using (true);

drop policy if exists "public insert order_items" on order_items;
create policy "public insert order_items" on order_items for insert with check (true);

drop policy if exists "public select order_items" on order_items;
create policy "public select order_items" on order_items for select using (true);

-- Authenticated (admin/staff) can manage everything
drop policy if exists "admin manage settings" on settings;
create policy "admin manage settings" on settings for update using (auth.role() = 'authenticated');

drop policy if exists "admin manage categories" on categories;
create policy "admin manage categories" on categories for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin manage menu_items" on menu_items;
create policy "admin manage menu_items" on menu_items for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin manage tables" on tables;
create policy "admin manage tables" on tables for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "admin update orders" on orders;
create policy "admin update orders" on orders for update using (auth.role() = 'authenticated');

-- ── Realtime ─────────────────────────────────────────────────────────────
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table order_items;

-- ── Sample data so the app isn't empty on first load (safe to delete) ──────
insert into categories (name, sort_order) values
  ('Starters', 1), ('Mains', 2), ('Drinks', 3)
on conflict do nothing;
