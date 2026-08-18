-- Store avatar as a string id (ninja, pizza, …), not an image.

alter table public.profiles
  add column if not exists avatar text not null default 'ninja';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email, is_guest, avatar_color, avatar)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'display_name',
      nullif(split_part(coalesce(new.email, 'guest'), '@', 1), ''),
      'Guest'
    ),
    new.email,
    coalesce((new.raw_user_meta_data->>'is_guest')::boolean, new.is_anonymous),
    15267332,
    coalesce(nullif(new.raw_user_meta_data->>'avatar', ''), 'ninja')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
