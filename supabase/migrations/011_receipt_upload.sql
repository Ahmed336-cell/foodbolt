-- Receipt upload: storage bucket + RLS, and a member-safe save RPC.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipts',
  'receipts',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.storage_room_id(object_name text)
returns uuid
language plpgsql
stable
as $$
declare
  folder text := split_part(object_name, '/', 1);
begin
  if folder ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' then
    return folder::uuid;
  end if;
  return null;
end;
$$;

drop policy if exists receipts_storage_select on storage.objects;
drop policy if exists receipts_storage_insert on storage.objects;
drop policy if exists receipts_storage_update on storage.objects;
drop policy if exists receipts_storage_delete on storage.objects;

create policy receipts_storage_select
on storage.objects for select
to authenticated
using (
  bucket_id = 'receipts'
  and public.is_room_member(public.storage_room_id(name))
);

create policy receipts_storage_insert
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'receipts'
  and public.is_room_member(public.storage_room_id(name))
);

create policy receipts_storage_update
on storage.objects for update
to authenticated
using (
  bucket_id = 'receipts'
  and public.is_room_member(public.storage_room_id(name))
)
with check (
  bucket_id = 'receipts'
  and public.is_room_member(public.storage_room_id(name))
);

create policy receipts_storage_delete
on storage.objects for delete
to authenticated
using (
  bucket_id = 'receipts'
  and public.is_room_member(public.storage_room_id(name))
);

create or replace function public.save_uploaded_receipt(
  p_room_id uuid,
  p_storage_path text,
  p_total numeric,
  p_status text default 'uploaded'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in.';
  end if;
  if not public.is_room_member(p_room_id) then
    raise exception 'Join the room first.';
  end if;
  if p_total is null or p_total <= 0 then
    raise exception 'Enter a valid receipt total.';
  end if;
  if p_status not in ('uploaded', 'skipped') then
    raise exception 'Enter a valid receipt total.';
  end if;

  insert into public.receipts as r (
    room_id, storage_path, total_amount, uploaded_by, status
  )
  values (
    p_room_id,
    p_storage_path,
    p_total,
    auth.uid(),
    p_status
  )
  on conflict (room_id) do update
    set storage_path = excluded.storage_path,
        total_amount = excluded.total_amount,
        uploaded_by = excluded.uploaded_by,
        status = excluded.status;

  if p_status = 'uploaded' then
    update public.rooms
       set phase = 'cost_review'
     where id = p_room_id;
  end if;
end;
$$;

grant execute on function public.save_uploaded_receipt(uuid, text, numeric, text)
  to authenticated;
