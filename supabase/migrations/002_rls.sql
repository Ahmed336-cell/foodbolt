-- FoodBolt RLS policies
-- Principle: members of a room can read room data; host-only for phase/lock/finalize.

create or replace function public.is_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.room_members m
    where m.room_id = p_room_id and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_room_host(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.rooms r
    where r.id = p_room_id and r.host_id = auth.uid()
  );
$$;

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.suggestions enable row level security;
alter table public.votes enable row level security;
alter table public.races enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.receipts enable row level security;
alter table public.cost_shares enable row level security;
alter table public.participant_shares enable row level security;
alter table public.payments enable row level security;

-- Profiles
create policy profiles_select on public.profiles for select using (true);
create policy profiles_update_own on public.profiles for update using (id = auth.uid());
create policy profiles_insert_own on public.profiles for insert with check (id = auth.uid());

-- Rooms
create policy rooms_select_member on public.rooms for select
  using (public.is_room_member(id) or host_id = auth.uid());
create policy rooms_insert_host on public.rooms for insert
  with check (host_id = auth.uid());
create policy rooms_update_host on public.rooms for update
  using (public.is_room_host(id));

-- Members
create policy members_select on public.room_members for select
  using (public.is_room_member(room_id));
create policy members_insert_self on public.room_members for insert
  with check (user_id = auth.uid());
create policy members_delete_self on public.room_members for delete
  using (user_id = auth.uid() or public.is_room_host(room_id));

-- Suggestions
create policy suggestions_select on public.suggestions for select
  using (public.is_room_member(room_id));
create policy suggestions_insert on public.suggestions for insert
  with check (public.is_room_member(room_id) and suggested_by = auth.uid());
create policy suggestions_delete on public.suggestions for delete
  using (suggested_by = auth.uid() or public.is_room_host(room_id));

-- Votes
create policy votes_select on public.votes for select
  using (public.is_room_member(room_id));
create policy votes_upsert on public.votes for insert
  with check (public.is_room_member(room_id) and user_id = auth.uid());
create policy votes_delete_own on public.votes for delete
  using (user_id = auth.uid());

-- Races (host writes, members read)
create policy races_select on public.races for select
  using (public.is_room_member(room_id));
create policy races_host_write on public.races for all
  using (public.is_room_host(room_id))
  with check (public.is_room_host(room_id));

-- Orders
create policy orders_select on public.orders for select
  using (public.is_room_member(room_id));
create policy orders_upsert_own on public.orders for insert
  with check (public.is_room_member(room_id) and user_id = auth.uid());
create policy orders_update_own on public.orders for update
  using (user_id = auth.uid());

create policy order_items_select on public.order_items for select
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id and public.is_room_member(o.room_id)
    )
  );
create policy order_items_write_own on public.order_items for all
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id and o.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_id and o.user_id = auth.uid()
    )
  );

-- Receipts / cost / payments
create policy receipts_select on public.receipts for select
  using (public.is_room_member(room_id));
create policy receipts_write_member on public.receipts for all
  using (public.is_room_member(room_id))
  with check (public.is_room_member(room_id));

create policy cost_select on public.cost_shares for select
  using (public.is_room_member(room_id));
create policy cost_host on public.cost_shares for all
  using (public.is_room_host(room_id))
  with check (public.is_room_host(room_id));

create policy participant_shares_select on public.participant_shares for select
  using (public.is_room_member(room_id));
create policy participant_shares_host on public.participant_shares for all
  using (public.is_room_host(room_id))
  with check (public.is_room_host(room_id));

create policy payments_select on public.payments for select
  using (public.is_room_member(room_id));
create policy payments_update_own on public.payments for update
  using (user_id = auth.uid() or public.is_room_host(room_id));
create policy payments_host_insert on public.payments for insert
  with check (public.is_room_host(room_id));

-- Storage bucket note:
-- create private bucket `receipts` in Supabase dashboard.
-- Policy: authenticated users who are room members may upload/read objects
-- under path `{room_id}/...` (enforce via storage RLS + path convention).
