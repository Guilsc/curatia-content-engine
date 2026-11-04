-- Curatia Alpha Foundation A4
-- First-login profile/onboarding and channel preference foundation.
-- Additive only; publishing credentials/tokens are intentionally NOT stored here.

alter table public.profiles
  add column if not exists role_title text,
  add column if not exists bio text,
  add column if not exists avatar_key text,
  add column if not exists onboarding_completed_at timestamptz;

alter table public.workspaces
  add column if not exists onboarding_completed_at timestamptz;

create table if not exists public.channel_catalog (
  key text primary key,
  display_name text not null,
  active boolean not null default true,
  sort_order integer not null default 100,
  capabilities text[] not null default '{}'::text[],
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.channel_catalog (key, display_name, sort_order, capabilities)
values
  ('linkedin', 'LinkedIn', 10, array['direct_publish','scheduled_publish','analytics']),
  ('instagram', 'Instagram', 20, array['scheduled_publish','analytics']),
  ('x', 'X', 30, array['scheduled_publish','analytics']),
  ('tiktok', 'TikTok', 40, array['direct_publish','scheduled_publish','draft_handoff','analytics']),
  ('medium', 'Medium', 50, array['manual_handoff'])
on conflict (key) do update
set display_name = excluded.display_name,
    sort_order = excluded.sort_order,
    capabilities = excluded.capabilities,
    updated_at = now();

create table if not exists public.workspace_channels (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  channel_key text not null references public.channel_catalog(key) on delete restrict,
  enabled boolean not null default true,
  is_primary boolean not null default false,
  preferred_publish_mode text
    check (preferred_publish_mode in ('direct_publish','scheduled_publish','draft_handoff','manual_handoff')),
  connection_status text not null default 'not_connected'
    check (connection_status in ('not_connected','connected','attention_required','disconnected')),
  provider text,
  provider_connection_ref text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (workspace_id, channel_key)
);

create unique index if not exists workspace_channels_one_primary_uq
  on public.workspace_channels (workspace_id)
  where is_primary;

create index if not exists workspace_channels_enabled_idx
  on public.workspace_channels (workspace_id, enabled);

drop trigger if exists channel_catalog_set_updated_at on public.channel_catalog;
create trigger channel_catalog_set_updated_at
before update on public.channel_catalog
for each row execute function public.set_updated_at();

drop trigger if exists workspace_channels_set_updated_at on public.workspace_channels;
create trigger workspace_channels_set_updated_at
before update on public.workspace_channels
for each row execute function public.set_updated_at();

alter table public.channel_catalog enable row level security;
alter table public.workspace_channels enable row level security;

-- Until authenticated RLS cutover, only trusted server-side services use these tables.
revoke all on table public.channel_catalog from anon, authenticated;
revoke all on table public.workspace_channels from anon, authenticated;
grant all on table public.channel_catalog to service_role;
grant all on table public.workspace_channels to service_role;

-- Connection references are opaque IDs only. OAuth/API secrets belong in secure provider/server-side storage,
-- never in workspace_channels.metadata or other browser-readable domain records.
