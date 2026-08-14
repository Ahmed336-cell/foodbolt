-- Fix account deletion: clear ALL suggestion FKs, then remove auth user.
-- Run this in Supabase → SQL Editor, then try Delete account again.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  deleted int;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Clear race winners pointing at this user's suggestions
  update public.races
     set winner_id = null
   where winner_id in (
           select s.id from public.suggestions s where s.suggested_by = uid
         );

  -- Clear room winners pointing at this user's suggestions
  update public.rooms
     set winner_suggestion_id = null
   where winner_suggestion_id in (
           select s.id from public.suggestions s where s.suggested_by = uid
         );

  -- Clear winners on rooms this user hosts
  update public.rooms
     set winner_suggestion_id = null
   where host_id = uid;

  update public.races
     set winner_id = null
   where room_id in (select id from public.rooms where host_id = uid);

  delete from public.suggestions where suggested_by = uid;
  delete from public.rooms where host_id = uid;

  update public.receipts
     set uploaded_by = null
   where uploaded_by = uid;

  delete from auth.users where id = uid;
  get diagnostics deleted = row_count;

  if deleted = 0 then
    raise exception 'Account could not be deleted';
  end if;
end;
$$;

alter function public.delete_my_account() owner to postgres;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
