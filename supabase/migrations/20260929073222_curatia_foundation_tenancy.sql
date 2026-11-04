-- Curatia Alpha Foundation A1
-- Additive tenancy, authorization, entitlement and audit foundation.
-- This migration intentionally does NOT backfill existing BA Content Engine rows.
-- Existing production records are assigned only after a real managed-auth Owner identity exists.

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  status text not null default 'active'
    check (status in ('active','suspended','archived')),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.platform_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('owner')),
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users(id) on delete set null
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','creator','viewer')),
  invited_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create index if not exists workspace_members_user_id_idx
  on public.workspace_members (user_id);

create table if not exists public.workspace_entitlements (
  workspace_id uuid primary key references public.workspaces(id) on delete cascade,
  max_active_signals integer not null default 100 check (max_active_signals > 0),
  max_sources integer not null default 500 check (max_sources > 0),
  max_ideas integer not null default 50 check (max_ideas > 0),
  max_content_items integer not null default 50 check (max_content_items > 0),
  max_visual_versions_per_content integer not null default 5
    check (max_visual_versions_per_content > 0),
  max_asset_storage_mb integer not null default 250 check (max_asset_storage_mb > 0),
  agent_log_retention_days integer not null default 30 check (agent_log_retention_days > 0),
  ai_payload_retention_days integer not null default 30 check (ai_payload_retention_days > 0),
  workflow_audit_retention_days integer not null default 365
    check (workflow_audit_retention_days > 0),
  analytics_retention_days integer not null default 365
    check (analytics_retention_days > 0),
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  event_type text not null check (length(trim(event_type)) > 0),
  target_type text,
  target_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists audit_events_workspace_created_idx
  on public.audit_events (workspace_id, created_at desc);

create index if not exists audit_events_actor_created_idx
  on public.audit_events (actor_user_id, created_at desc);

-- Add nullable ownership to current domains. Backfill and NOT NULL enforcement are later migrations.
alter table public.scout_runs
  add column if not exists workspace_id uuid references public.workspaces(id) on delete restrict;

alter table public.sources
  add column if not exists workspace_id uuid references public.workspaces(id) on delete restrict;

alter table public.signals
  add column if not exists workspace_id uuid references public.workspaces(id) on delete restrict;

alter table public.portfolio_publications
  add column if not exists workspace_id uuid references public.workspaces(id) on delete restrict;

create index if not exists scout_runs_workspace_idx on public.scout_runs (workspace_id);
create index if not exists sources_workspace_idx on public.sources (workspace_id);
create index if not exists signals_workspace_state_idx on public.signals (workspace_id, state);
create index if not exists portfolio_publications_workspace_idx
  on public.portfolio_publications (workspace_id);

-- Discovery interests are included in Foundation A because they define future Scout scope.
create table if not exists public.discovery_interests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  label text not null check (length(trim(label)) > 0),
  normalized_label text generated always as (lower(trim(label))) stored,
  source text not null default 'user_added'
    check (source in ('system_default','user_added')),
  active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, normalized_label)
);

create index if not exists discovery_interests_workspace_active_idx
  on public.discovery_interests (workspace_id, active);

-- Historical snapshots allow later interest changes without rewriting old discovery provenance.
alter table public.scout_runs
  add column if not exists discovery_interest_snapshot jsonb not null default '[]'::jsonb;

alter table public.signals
  add column if not exists discovery_tags text[] not null default '{}'::text[];

-- Reuse the existing updated-at trigger function created by the core schema.
drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists workspaces_set_updated_at on public.workspaces;
create trigger workspaces_set_updated_at
before update on public.workspaces
for each row execute function public.set_updated_at();

drop trigger if exists workspace_members_set_updated_at on public.workspace_members;
create trigger workspace_members_set_updated_at
before update on public.workspace_members
for each row execute function public.set_updated_at();

drop trigger if exists workspace_entitlements_set_updated_at on public.workspace_entitlements;
create trigger workspace_entitlements_set_updated_at
before update on public.workspace_entitlements
for each row execute function public.set_updated_at();

drop trigger if exists discovery_interests_set_updated_at on public.discovery_interests;
create trigger discovery_interests_set_updated_at
before update on public.discovery_interests
for each row execute function public.set_updated_at();

-- RLS is enabled immediately. Policies arrive with authenticated cutover after Owner bootstrap.
alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.platform_roles enable row level security;
alter table public.workspace_members enable row level security;
alter table public.workspace_entitlements enable row level security;
alter table public.audit_events enable row level security;
alter table public.discovery_interests enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.workspaces from anon, authenticated;
revoke all on table public.platform_roles from anon, authenticated;
revoke all on table public.workspace_members from anon, authenticated;
revoke all on table public.workspace_entitlements from anon, authenticated;
revoke all on table public.audit_events from anon, authenticated;
revoke all on table public.discovery_interests from anon, authenticated;

grant all on table public.profiles to service_role;
grant all on table public.workspaces to service_role;
grant all on table public.platform_roles to service_role;
grant all on table public.workspace_members to service_role;
grant all on table public.workspace_entitlements to service_role;
grant all on table public.audit_events to service_role;
grant all on table public.discovery_interests to service_role;
