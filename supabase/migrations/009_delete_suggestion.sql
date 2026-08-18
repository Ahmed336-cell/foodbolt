-- Remove a suggested restaurant without PostgREST .single() / winner FK blocks.

alter table public.rooms drop constraint if exists rooms_winner_fk;
alter table public.rooms
  add constraint rooms_winner_fk
  foreign key (winner_suggestion_id) references public.suggestions (id)
  on delete set null;

alter table public.races drop constraint if exists races_winner_id_fkey;
alter table public.races
  add constraint races_winner_id_fkey
  foreign key (winner_id) references public.suggestions (id)
  on delete set null;

create or replace function public.delete_suggestion(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  sid uuid;
  rid uuid;
  owner uuid;
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not signed in.';
  end if;

  select s.id, s.room_id, s.suggested_by
    into sid, rid, owner
    from public.suggestions s
   where s.id = p_id;

  if sid is null then
    raise exception 'Restaurant not found.';
  end if;

  if not public.is_room_member(rid) then
    raise exception 'Join the room first.';
  end if;

  if owner <> uid and not public.is_room_host(rid) then
    raise exception 'You don''t have permission to perform this action.';
  end if;

  update public.rooms
     set winner_suggestion_id = null
   where winner_suggestion_id = sid;

  update public.races
     set winner_id = null
   where winner_id = sid;

  delete from public.suggestions where id = sid;
end;
$$;

grant execute on function public.delete_suggestion(uuid) to authenticated;
