-- Payment requests: members request, host confirms/rejects
alter table public.payments
  add column if not exists payment_requested boolean not null default false;
