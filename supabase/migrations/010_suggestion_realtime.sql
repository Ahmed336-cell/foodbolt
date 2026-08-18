-- DELETE/UPDATE payloads must include all columns so Realtime + RLS can
-- authorize other room members. Default replica identity only sends the PK,
-- so friends never see suggestion deletes.

alter table public.suggestions replica identity full;
alter table public.votes replica identity full;
alter table public.room_members replica identity full;
alter table public.rooms replica identity full;

-- Server-side broadcast so other phones refresh even if postgres_changes
-- filters the DELETE. realtime.send exists on current Supabase; skip if not.
do $$
begin
  if exists (
    select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'realtime'
       and p.proname = 'send'
  ) then
    execute $fn$
      create or replace function public.broadcast_suggestion_change()
      returns trigger
      language plpgsql
      security definer
      set search_path = public
      as $body$
      declare
        rid uuid;
      begin
        rid := coalesce(new.room_id, old.room_id);
        perform realtime.send(
          jsonb_build_object('op', tg_op, 'room_id', rid),
          'suggestions',
          'room-suggestions-' || rid::text,
          false
        );
        return coalesce(new, old);
      end;
      $body$;
    $fn$;

    execute 'drop trigger if exists suggestions_broadcast on public.suggestions';
    execute $tg$
      create trigger suggestions_broadcast
      after insert or update or delete on public.suggestions
      for each row execute function public.broadcast_suggestion_change()
    $tg$;
  end if;
end $$;
