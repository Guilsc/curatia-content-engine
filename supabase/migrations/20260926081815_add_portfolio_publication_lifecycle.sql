alter table public.portfolio_publications
  add column if not exists publication_status text not null default 'published',
  add column if not exists scheduled_at timestamptz,
  add column if not exists metricool_post_id text,
  add column if not exists metricool_post_uuid text;

alter table public.portfolio_publications
  add constraint portfolio_publications_status_check
  check (publication_status in ('scheduled','published','cancelled','failed'));

create unique index if not exists portfolio_publications_metricool_uuid_uidx
  on public.portfolio_publications (metricool_post_uuid)
  where metricool_post_uuid is not null;

update public.portfolio_publications
set publication_status = 'published'
where publication_status is distinct from 'published';
