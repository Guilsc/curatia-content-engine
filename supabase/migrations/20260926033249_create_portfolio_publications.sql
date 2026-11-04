create table public.portfolio_publications (
  public_id text primary key
    check (length(trim(public_id)) > 0),
  channel text not null
    check (channel in ('linkedin')),
  title text not null
    check (length(trim(title)) > 0),
  summary text not null
    check (length(trim(summary)) > 0),
  category text,
  url text not null unique
    check (url ~ '^https://(www\.)?linkedin\.com/'),
  published_at timestamptz not null,
  portfolio boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index portfolio_publications_public_feed_idx
  on public.portfolio_publications (channel, published_at desc)
  where portfolio = true;

create trigger portfolio_publications_set_updated_at
before update on public.portfolio_publications
for each row execute function public.set_updated_at();

alter table public.portfolio_publications enable row level security;

revoke all on table public.portfolio_publications from anon, authenticated;
grant all on table public.portfolio_publications to service_role;
