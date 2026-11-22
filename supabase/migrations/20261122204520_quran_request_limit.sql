create schema if not exists madar_private;

create table madar_private.quran_request_limit (
  id boolean primary key default true check (id),
  minute bigint not null,
  requests integer not null
);

alter table madar_private.quran_request_limit enable row level security;

grant usage on schema madar_private to service_role;
grant select, insert, update on madar_private.quran_request_limit to service_role;

create function public.take_quran_request()
returns boolean
language sql
security invoker
set search_path = ''
as $$
  insert into madar_private.quran_request_limit as state (id, minute, requests)
    values (true, floor(extract(epoch from statement_timestamp()) / 60)::bigint, 1)
  on conflict (id) do update
    set minute = excluded.minute,
        requests = case when state.minute = excluded.minute
           then least(state.requests + 1, 121) else 1 end
  returning requests <= 120;
$$;

revoke execute on function public.take_quran_request() from public, anon, authenticated;
grant execute on function public.take_quran_request() to service_role;
