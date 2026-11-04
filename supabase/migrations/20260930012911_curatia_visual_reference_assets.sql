
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('curatia-visual-references','curatia-visual-references',false,10485760,array['image/png','image/jpeg','image/webp','image/gif'])
on conflict (id) do update set public=false,file_size_limit=10485760,allowed_mime_types=array['image/png','image/jpeg','image/webp','image/gif'];

create table if not exists public.content_reference_assets (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  content_item_id text not null references public.content_items(id) on delete cascade,
  storage_bucket text not null default 'curatia-visual-references',
  storage_path text not null unique,
  file_name text not null,
  mime_type text not null,
  file_size bigint not null check (file_size > 0 and file_size <= 10485760),
  purpose text not null default 'visual_reference' check (purpose in ('visual_reference')),
  interpretation text,
  interpretation_provider text,
  interpretation_model text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists content_reference_assets_item_idx on public.content_reference_assets(workspace_id,content_item_id,created_at desc);
alter table public.content_reference_assets enable row level security;
drop policy if exists "workspace members read content references" on public.content_reference_assets;
create policy "workspace members read content references" on public.content_reference_assets for select using (
 exists(select 1 from public.workspace_members wm where wm.workspace_id=content_reference_assets.workspace_id and wm.user_id=auth.uid())
);
drop policy if exists "workspace creators manage content references" on public.content_reference_assets;
create policy "workspace creators manage content references" on public.content_reference_assets for all using (
 exists(select 1 from public.workspace_members wm where wm.workspace_id=content_reference_assets.workspace_id and wm.user_id=auth.uid() and wm.role in ('admin','creator'))
) with check (
 exists(select 1 from public.workspace_members wm where wm.workspace_id=content_reference_assets.workspace_id and wm.user_id=auth.uid() and wm.role in ('admin','creator'))
);
