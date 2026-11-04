
insert into public.channel_catalog (key, display_name, active, sort_order)
values
 ('linkedin','LinkedIn',true,10),('instagram','Instagram',true,20),('x','X',true,30),('tiktok','TikTok',true,40),
 ('youtube','YouTube',true,50),('podcast','Podcast',true,60),('newsletter','Newsletter',true,70),('blog','Blog / Website',true,80)
on conflict (key) do update set display_name=excluded.display_name, active=true, sort_order=excluded.sort_order, updated_at=now();
update public.channel_catalog set active=false where key='medium';

alter table public.workspace_preferences
 add column if not exists preference_provenance jsonb not null default '{}'::jsonb;

create table if not exists public.content_visual_assets (
 id uuid primary key default gen_random_uuid(),
 content_item_id text not null references public.content_items(id) on delete cascade,
 workspace_id uuid references public.workspaces(id) on delete cascade,
 version integer not null default 1,
 source text not null default 'generated' check (source in ('generated','uploaded')),
 prompt text,
 asset_url text not null,
 selected boolean not null default false,
 provider text,
 provider_asset_ref text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 unique(content_item_id, version)
);
create index if not exists content_visual_assets_item_idx on public.content_visual_assets(content_item_id, created_at desc);
alter table public.content_visual_assets enable row level security;
