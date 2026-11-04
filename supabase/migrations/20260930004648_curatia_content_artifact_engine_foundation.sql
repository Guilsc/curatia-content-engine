
alter table public.content_items
  add column if not exists content_format text not null default 'text_post';

alter table public.content_items
  drop constraint if exists content_items_content_format_check;

alter table public.content_items
  add constraint content_items_content_format_check
  check (content_format in ('text_post','text_visual','image_post','carousel','video','newsletter','article'));

create table if not exists public.content_artifacts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  content_item_id text not null references public.content_items(id) on delete cascade,
  artifact_type text not null check (artifact_type in ('text','caption','carousel','image','video','document','subject','body')),
  version integer not null default 1 check (version > 0),
  content jsonb not null default '{}'::jsonb,
  status text not null default 'working' check (status in ('working','selected','superseded')),
  source text not null default 'user' check (source in ('user','curatia','imported')),
  operation text,
  skill_ids text[] not null default '{}',
  skill_router_version text,
  provider text,
  model text,
  provenance jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(content_item_id, artifact_type, version)
);

create index if not exists content_artifacts_item_idx
  on public.content_artifacts(workspace_id, content_item_id, artifact_type, version desc);

alter table public.content_artifacts enable row level security;

drop policy if exists "workspace members read content artifacts" on public.content_artifacts;
create policy "workspace members read content artifacts"
on public.content_artifacts for select
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id=content_artifacts.workspace_id and wm.user_id=auth.uid()
));

drop policy if exists "workspace creators manage content artifacts" on public.content_artifacts;
create policy "workspace creators manage content artifacts"
on public.content_artifacts for all
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id=content_artifacts.workspace_id and wm.user_id=auth.uid() and wm.role in ('admin','creator')
))
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id=content_artifacts.workspace_id and wm.user_id=auth.uid() and wm.role in ('admin','creator')
));

create table if not exists public.skill_capability_gaps (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  content_item_id text references public.content_items(id) on delete set null,
  agent text not null,
  task text not null,
  channel text,
  content_format text,
  operation text,
  gap_key text not null,
  description text not null,
  status text not null default 'open' check (status in ('open','candidate_found','resolved','dismissed')),
  occurrences integer not null default 1,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  unique(workspace_id,gap_key)
);

alter table public.skill_capability_gaps enable row level security;

drop policy if exists "workspace members read skill gaps" on public.skill_capability_gaps;
create policy "workspace members read skill gaps"
on public.skill_capability_gaps for select
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id=skill_capability_gaps.workspace_id and wm.user_id=auth.uid()
));

drop policy if exists "workspace creators manage skill gaps" on public.skill_capability_gaps;
create policy "workspace creators manage skill gaps"
on public.skill_capability_gaps for all
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id=skill_capability_gaps.workspace_id and wm.user_id=auth.uid() and wm.role in ('admin','creator')
))
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id=skill_capability_gaps.workspace_id and wm.user_id=auth.uid() and wm.role in ('admin','creator')
));

update public.content_items
set content_format = case
  when final_visual_reference is not null and coalesce(final_copy,draft_copy) is not null then 'text_visual'
  else 'text_post'
end
where content_format='text_post';
