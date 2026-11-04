alter table public.portfolio_publications
  add column if not exists source_system text not null default 'manual',
  add column if not exists source_external_id text,
  add column if not exists last_synced_at timestamptz;

alter table public.portfolio_publications
  add constraint portfolio_publications_source_system_check
  check (source_system in ('manual', 'metricool', 'linkedin', 'ba_content_engine'));

create unique index if not exists portfolio_publications_source_external_id_uidx
  on public.portfolio_publications (source_system, source_external_id)
  where source_external_id is not null;

update public.portfolio_publications
set source_system = case
      when public_id like 'linkedin-750%' then 'metricool'
      else 'manual'
    end,
    source_external_id = case
      when public_id like 'linkedin-750%' then replace(public_id, 'linkedin-', '')
      else null
    end,
    last_synced_at = now()
where last_synced_at is null;
