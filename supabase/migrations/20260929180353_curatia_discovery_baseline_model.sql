
alter table public.workspace_preferences
add column if not exists discovery_baselines text[] not null default array['Technology']::text[];

update public.workspace_preferences
set discovery_baselines=array['Technology']::text[]
where discovery_baselines is null or cardinality(discovery_baselines)=0;

alter table public.workspace_preferences
alter column discovery_watchlists set default '{}'::text[];
