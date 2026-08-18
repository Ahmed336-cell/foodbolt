-- Host (admin) can correct item prices after orders are locked.

create or replace function public.update_order_item_price(
  p_item_id uuid,
  p_price numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  rid uuid;
begin
  if auth.uid() is null then
    raise exception 'Not signed in.';
  end if;
  if p_price is null or p_price < 0 then
    raise exception 'Enter a valid price.';
  end if;

  select o.room_id into rid
    from public.order_items i
    join public.orders o on o.id = i.order_id
   where i.id = p_item_id;

  if rid is null then
    raise exception 'Not found.';
  end if;
  if not public.is_room_host(rid) then
    raise exception 'Only the host can update prices.';
  end if;

  update public.order_items
     set price = p_price
   where id = p_item_id;
end;
$$;

grant execute on function public.update_order_item_price(uuid, numeric)
  to authenticated;
