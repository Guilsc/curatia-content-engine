-- Curatia Alpha Foundation A6
-- Enforce initial workspace capacity without silently deleting editorial knowledge.

create schema if not exists private;

create or replace function private.enforce_signal_capacity()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_limit integer;
  v_count integer;
begin
  if new.state not in ('New','Watch','Explore') then
    return new;
  end if;

  select max_active_signals into v_limit
  from public.workspace_entitlements
  where workspace_id = new.workspace_id;

  if v_limit is null then
    raise exception 'Workspace entitlements are missing.';
  end if;

  select count(*) into v_count
  from public.signals
  where workspace_id = new.workspace_id
    and state in ('New','Watch','Explore');

  if tg_op = 'INSERT' and v_count >= v_limit then
    raise exception 'Active Signal capacity reached (%). Archive or resolve Signals before adding more.', v_limit;
  end if;

  if tg_op = 'UPDATE'
     and old.state not in ('New','Watch','Explore')
     and v_count >= v_limit then
    raise exception 'Active Signal capacity reached (%). Archive or resolve Signals before reactivating.', v_limit;
  end if;

  return new;
end;
$$;

drop trigger if exists signals_capacity_guard on public.signals;
create trigger signals_capacity_guard
before insert or update of state, workspace_id on public.signals
for each row execute function private.enforce_signal_capacity();

create or replace function private.enforce_source_capacity()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_limit integer;
  v_count integer;
begin
  select max_sources into v_limit
  from public.workspace_entitlements
  where workspace_id = new.workspace_id;

  if v_limit is null then
    raise exception 'Workspace entitlements are missing.';
  end if;

  select count(*) into v_count
  from public.sources
  where workspace_id = new.workspace_id;

  if v_count >= v_limit then
    raise exception 'Source capacity reached (%). Cleanup is required before adding more.', v_limit;
  end if;

  return new;
end;
$$;

drop trigger if exists sources_capacity_guard on public.sources;
create trigger sources_capacity_guard
before insert on public.sources
for each row execute function private.enforce_source_capacity();
