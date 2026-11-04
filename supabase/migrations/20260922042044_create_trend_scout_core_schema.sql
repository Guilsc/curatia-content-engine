
create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.scout_runs (
  id uuid primary key default gen_random_uuid(),
  run_key text not null unique,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  status text not null default 'running'
    check (status in ('running','completed','failed','no_new_signals')),
  discovery_window_hours smallint
    check (discovery_window_hours is null or discovery_window_hours > 0),
  signals_found integer not null default 0 check (signals_found >= 0),
  new_signals integer not null default 0 check (new_signals >= 0),
  summary text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.sources (
  id uuid primary key default gen_random_uuid(),
  source_key text unique,
  canonical_url text,
  title text not null,
  publisher text,
  author text,
  source_type text not null default 'Other',
  external_id text,
  published_at timestamptz,
  detected_at timestamptz not null default now(),
  accessed_at timestamptz,
  last_verified_at timestamptz,
  summary text,
  topics text[] not null default '{}'::text[],
  tags text[] not null default '{}'::text[],
  credibility_notes text,
  relevance_notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index sources_canonical_url_uq
  on public.sources (canonical_url)
  where canonical_url is not null;

create unique index sources_publisher_external_id_uq
  on public.sources (publisher, external_id)
  where publisher is not null and external_id is not null;

create table public.signals (
  id uuid primary key default gen_random_uuid(),
  signal_key text not null unique,
  title text not null,
  summary text,
  state text not null default 'New'
    check (state in ('New','Watch','Explore','Promoted','Ignored','Archived')),
  first_published_at timestamptz,
  detected_at timestamptz not null default now(),
  preliminary_ba_relevance text,
  why_it_may_matter text,
  why_now text,
  ba_impact text,
  second_order_implication text,
  evidence_strength text
    check (evidence_strength is null or evidence_strength in ('Strong','Moderate','Weak')),
  saturation text
    check (saturation is null or saturation in ('Low','Medium','High')),
  backlog_overlap text,
  strongest_editorial_angle text,
  editorial_potential text
    check (editorial_potential is null or editorial_potential in ('Watch','Explore','Candidate')),
  archive_eligible boolean not null default false,
  promoted_at timestamptz,
  ignored_at timestamptz,
  archived_at timestamptz,
  first_seen_run_id uuid references public.scout_runs(id) on delete set null,
  last_seen_run_id uuid references public.scout_runs(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index signals_state_idx on public.signals (state);
create index signals_detected_at_idx on public.signals (detected_at desc);
create index signals_archive_eligible_idx on public.signals (archive_eligible)
  where archive_eligible = true;

create table public.signal_sources (
  signal_id uuid not null references public.signals(id) on delete cascade,
  source_id uuid not null references public.sources(id) on delete restrict,
  role text not null default 'additional'
    check (role in ('primary','additional')),
  created_at timestamptz not null default now(),
  primary key (signal_id, source_id)
);

create unique index one_primary_source_per_signal_uq
  on public.signal_sources (signal_id)
  where role = 'primary';

create index signal_sources_source_id_idx on public.signal_sources (source_id);

create trigger sources_set_updated_at
before update on public.sources
for each row execute function public.set_updated_at();

create trigger signals_set_updated_at
before update on public.signals
for each row execute function public.set_updated_at();

alter table public.scout_runs enable row level security;
alter table public.sources enable row level security;
alter table public.signals enable row level security;
alter table public.signal_sources enable row level security;

revoke all on table public.scout_runs from anon, authenticated;
revoke all on table public.sources from anon, authenticated;
revoke all on table public.signals from anon, authenticated;
revoke all on table public.signal_sources from anon, authenticated;

grant all on table public.scout_runs to service_role;
grant all on table public.sources to service_role;
grant all on table public.signals to service_role;
grant all on table public.signal_sources to service_role;
