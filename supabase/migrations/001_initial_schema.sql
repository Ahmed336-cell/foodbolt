-- FoodBolt initial schema (Supabase / Postgres)
-- Apply when connecting real backend. Not used in mock mode.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  avatar_color int not null default 15267332,
  is_guest boolean not null default false,
  email text,
  created_at timestamptz not null default now()
);

create type public.room_phase as enum (
  'lobby',
  'suggestions',
  'voting',
  'race',
  'restaurant_selected',
  'ordering',
  'orders_locked',
  'receipt',
  'cost_review',
  'payment_summary',
  'completed'
);

create type public.selection_mode as enum (
  'race_direct',
  'vote_with_tie_race',
  'vote_only'
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  host_id uuid not null references public.profiles (id),
  phase public.room_phase not null default 'lobby',
  selection_mode public.selection_mode not null default 'vote_with_tie_race',
  max_participants int not null default 12,
  voting_duration_seconds int not null default 60,
  max_suggestions int not null default 8,
  allow_member_suggestions boolean not null default true,
  guest_access boolean not null default true,
  vote_limit int not null default 1,
  winner_suggestion_id uuid,
  invite_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.room_members (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null check (role in ('host', 'member')),
  is_online boolean not null default true,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.suggestions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms (id) on delete cascade,
  name text not null,
  category text,
  note text,
  image_url text,
  suggested_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

alter table public.rooms
  add constraint rooms_winner_fk
  foreign key (winner_suggestion_id) references public.suggestions (id);

create table if not exists public.votes (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  suggestion_id uuid not null references public.suggestions (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (room_id, user_id, suggestion_id)
);

create table if not exists public.races (
  room_id uuid primary key references public.rooms (id) on delete cascade,
  suggestion_ids uuid[] not null,
  winner_id uuid references public.suggestions (id),
  status text not null check (status in ('idle', 'countdown', 'racing', 'finished')),
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  submitted boolean not null default false,
  unique (room_id, user_id)
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  name text not null,
  quantity int not null default 1,
  price numeric(12,2) not null,
  notes text
);

create table if not exists public.receipts (
  room_id uuid primary key references public.rooms (id) on delete cascade,
  storage_path text,
  total_amount numeric(12,2),
  uploaded_by uuid references public.profiles (id),
  status text not null default 'none' check (status in ('none', 'uploaded')),
  created_at timestamptz not null default now()
);

create table if not exists public.cost_shares (
  room_id uuid primary key references public.rooms (id) on delete cascade,
  receipt_total numeric(12,2) not null,
  expected_orders_total numeric(12,2) not null default 0,
  delivery_fee numeric(12,2) not null default 0,
  service_fee numeric(12,2) not null default 0,
  tax numeric(12,2) not null default 0,
  discount numeric(12,2) not null default 0,
  other_fee numeric(12,2) not null default 0,
  confirmed boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.participant_shares (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  order_subtotal numeric(12,2) not null,
  extras_share numeric(12,2) not null default 0,
  adjustment numeric(12,2) not null default 0,
  final_amount numeric(12,2) not null,
  primary key (room_id, user_id)
);

create table if not exists public.payments (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  amount numeric(12,2) not null,
  paid boolean not null default false,
  primary key (room_id, user_id)
);

-- Realtime
alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.room_members;
alter publication supabase_realtime add table public.suggestions;
alter publication supabase_realtime add table public.votes;
alter publication supabase_realtime add table public.races;
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.order_items;
alter publication supabase_realtime add table public.receipts;
alter publication supabase_realtime add table public.cost_shares;
alter publication supabase_realtime add table public.participant_shares;
alter publication supabase_realtime add table public.payments;
