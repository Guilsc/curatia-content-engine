
create table if not exists public.ai_capability_routing (
  id uuid primary key default gen_random_uuid(),
  scope text not null default 'platform' check (scope in ('platform','workspace')),
  workspace_id uuid null references public.workspaces(id) on delete cascade,
  capability text not null check (capability in ('analysis_research','writing','image_generation','video_generation','multimodal_understanding')),
  preferred_model text not null default 'auto',
  fallback_mode text not null default 'auto' check (fallback_mode in ('auto','none')),
  active boolean not null default true,
  updated_by uuid null,
  updated_at timestamptz not null default now(),
  unique nulls not distinct (scope, workspace_id, capability),
  check ((scope='platform' and workspace_id is null) or (scope='workspace' and workspace_id is not null))
);
alter table public.ai_capability_routing enable row level security;
drop policy if exists "authenticated read ai capability routing" on public.ai_capability_routing;
create policy "authenticated read ai capability routing" on public.ai_capability_routing for select to authenticated using (true);
insert into public.ai_capability_routing(scope,workspace_id,capability,preferred_model,fallback_mode)
values
 ('platform',null,'analysis_research','gpt-5.6-sol','auto'),
 ('platform',null,'writing','gpt-5.6-sol','auto'),
 ('platform',null,'image_generation','auto','auto'),
 ('platform',null,'video_generation','auto','auto'),
 ('platform',null,'multimodal_understanding','auto','auto')
on conflict (scope,workspace_id,capability) do nothing;
