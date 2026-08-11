-- FoodBolt follow-up schema for Supabase live mode
-- Profile auto-create, race tiebreaker flag, skipped receipts, join-by-code RLS

-- Auto profile on auth.users insert (covers email + anonymous guests)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email, is_guest, avatar_color)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'display_name',
      nullif(split_part(coalesce(new.email, 'guest'), '@', 1), ''),
      'Guest'
    ),
    new.email,
    coalesce((new.raw_user_meta_data->>'is_guest')::boolean, new.is_anonymous),
    15267332
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Race tiebreaker flag
alter table public.races
  add column if not exists is_tiebreaker boolean not null default false;

-- Receipts may be skipped (pay own order)
alter table public.receipts drop constraint if exists receipts_status_check;
alter table public.receipts
  add constraint receipts_status_check
  check (status in ('none', 'uploaded', 'skipped'));

-- Allow authenticated users to discover lobby rooms (needed before join membership)
drop policy if exists rooms_select_member on public.rooms;
drop policy if exists rooms_select_by_code on public.rooms;
create policy rooms_select on public.rooms
  for select
  using (
    public.is_room_member(id)
    or host_id = auth.uid()
    or phase = 'lobby'
  );

-- Payments: allow delete so confirm/skip can rewrite rows
drop policy if exists payments_host_delete on public.payments;
create policy payments_host_delete on public.payments
  for delete
  using (public.is_room_host(room_id));

-- Members may update their own online flag
drop policy if exists members_update_self on public.room_members;
create policy members_update_self on public.room_members
  for update
  using (user_id = auth.uid() or public.is_room_host(room_id));

-- Lookup helper for invite codes
create or replace function public.get_room_by_code(p_code text)
returns setof public.rooms
language sql
stable
security definer
set search_path = public
as $$
  select * from public.rooms
  where code = upper(trim(p_code))
  limit 1;
$$;

grant execute on function public.get_room_by_code(text) to authenticated;
