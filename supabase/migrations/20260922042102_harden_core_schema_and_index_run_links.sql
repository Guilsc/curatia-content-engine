
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create index if not exists signals_first_seen_run_id_idx
  on public.signals (first_seen_run_id);

create index if not exists signals_last_seen_run_id_idx
  on public.signals (last_seen_run_id);
