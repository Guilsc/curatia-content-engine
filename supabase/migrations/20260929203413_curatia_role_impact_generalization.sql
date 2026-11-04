
alter table public.signals add column if not exists role_impact text;
update public.signals set role_impact=ba_impact where role_impact is null and ba_impact is not null;
