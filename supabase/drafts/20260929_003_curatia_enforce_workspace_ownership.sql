-- Curatia Alpha Foundation A3
-- Enforce workspace ownership only AFTER Owner bootstrap and legacy backfill validation.
-- This migration must not be applied before all current rows have workspace_id.

do $$
begin
  if exists (select 1 from public.scout_runs where workspace_id is null)
     or exists (select 1 from public.sources where workspace_id is null)
     or exists (select 1 from public.signals where workspace_id is null)
     or exists (select 1 from public.portfolio_publications where workspace_id is null)
  then
    raise exception 'Workspace backfill is incomplete. Refusing to enforce tenancy.';
  end if;
end;
$$;

alter table public.scout_runs alter column workspace_id set not null;
alter table public.sources alter column workspace_id set not null;
alter table public.signals alter column workspace_id set not null;
alter table public.portfolio_publications alter column workspace_id set not null;

-- New records are unique inside a workspace, not globally across the entire Curatia platform.
alter table public.scout_runs drop constraint if exists scout_runs_run_key_key;
create unique index if not exists scout_runs_workspace_run_key_uq
  on public.scout_runs (workspace_id, run_key);

alter table public.signals drop constraint if exists signals_signal_key_key;
create unique index if not exists signals_workspace_signal_key_uq
  on public.signals (workspace_id, signal_key);

alter table public.sources drop constraint if exists sources_source_key_key;
create unique index if not exists sources_workspace_source_key_uq
  on public.sources (workspace_id, source_key)
  where source_key is not null;

drop index if exists public.sources_canonical_url_uq;
create unique index if not exists sources_workspace_canonical_url_uq
  on public.sources (workspace_id, canonical_url)
  where canonical_url is not null;

drop index if exists public.sources_publisher_external_id_uq;
create unique index if not exists sources_workspace_publisher_external_id_uq
  on public.sources (workspace_id, publisher, external_id)
  where publisher is not null and external_id is not null;

-- Prevent cross-workspace Signal/Source links.
create or replace function public.enforce_signal_source_workspace()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_signal_workspace uuid;
  v_source_workspace uuid;
begin
  select workspace_id into v_signal_workspace from public.signals where id = new.signal_id;
  select workspace_id into v_source_workspace from public.sources where id = new.source_id;

  if v_signal_workspace is null or v_source_workspace is null
     or v_signal_workspace <> v_source_workspace then
    raise exception 'Signal and Source must belong to the same workspace.';
  end if;

  return new;
end;
$$;

drop trigger if exists signal_sources_workspace_guard on public.signal_sources;
create trigger signal_sources_workspace_guard
before insert or update on public.signal_sources
for each row execute function public.enforce_signal_source_workspace();
